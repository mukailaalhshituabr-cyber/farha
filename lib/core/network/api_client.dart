// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../data/services/local_storage_service.dart';
import 'api_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  final LocalStorageService _storage;
  bool    _isRefreshing = false;
  String? _adminToken;

  void setAdminToken(String token)  => _adminToken = token;
  void clearAdminToken()            => _adminToken = null;
  bool get hasAdminToken            => _adminToken != null;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout:    ApiConstants.sendTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      validateStatus: (_) => true, // handle all status codes ourselves
    ));

    _dio.interceptors.addAll([
      ApiLoggingInterceptor(),
      InterceptorsWrapper(
        onRequest:  _onRequest,
        onResponse: _onResponse,
        onError:    _onError,
      ),
    ]);
  }

  // ── Attach JWT token to every request ────────────────────────────────────
  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Admin token takes priority when admin is active
    final token = _adminToken ?? await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization']   = 'Bearer $token';
      options.headers['X-Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ── Handle 401 — try refresh, then retry once ─────────────────────────
  Future<void> _onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry the original request with new token
          final token = await _storage.getAccessToken();
          response.requestOptions.headers['Authorization'] = 'Bearer $token';
          final retry = await _dio.fetch(response.requestOptions);
          _isRefreshing = false;
          return handler.resolve(retry);
        }
      } catch (_) {}
      _isRefreshing = false;
      await _storage.clearAll();
      handler.next(response); // let the caller handle it
      return;
    }
    handler.next(response);
  }

  Future<void> _onError(DioException err, ErrorInterceptorHandler handler) async {
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await Dio().post(ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final newAccess = res.data['data']['access_token'] as String;
        await _storage.saveTokens(accessToken: newAccess, refreshToken: refreshToken);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Request helpers ───────────────────────────────────────────────────
  Future<ApiResponse> get(String url, {Map<String, dynamic>? params}) async {
    return _handle(() => _dio.get(url, queryParameters: params));
  }

  Future<ApiResponse> post(String url, {dynamic data}) async {
    return _handle(() => _dio.post(url, data: data));
  }

  Future<ApiResponse> put(String url, {dynamic data}) async {
    return _handle(() => _dio.put(url, data: data));
  }

  Future<ApiResponse> delete(String url, {Map<String, dynamic>? params}) async {
    return _handle(() => _dio.delete(url, queryParameters: params));
  }

  Future<ApiResponse> postForm(String url, FormData formData) async {
    // PHP-FPM strips Authorization headers on multipart requests, so we also
    // pass the token as ?_token= — config.php uses it as a dedicated fallback.
    final token = await _storage.getAccessToken();
    return _handle(() => _dio.post(
      url,
      data: formData,
      queryParameters: token != null ? {'_token': token} : null,
      // No Options.contentType — Dio auto-sets multipart/form-data; boundary=...
      // from FormData. Overriding it here strips the boundary and breaks $_FILES.
    ));
  }

  Future<ApiResponse> _handle(Future<Response> Function() request) async {
    try {
      final response = await request();
      // Safely read keys — response.data may be null, a String (HTML error
      // page), or a Map. Treat anything other than a proper JSON map as failure.
      final raw = response.data;
      final Map<String, dynamic> data =
          raw is Map ? Map<String, dynamic>.from(raw) : {};
      return ApiResponse(
        success:    data['success'] == true,
        statusCode: response.statusCode ?? 0,
        message:    data['message'] as String? ?? '',
        data:       data['data'],
        errors:     data['errors'],
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return ApiResponse.networkError('Request timed out. Please check your internet connection.');
      }
      if (e.type == DioExceptionType.connectionError) {
        return ApiResponse.networkError('Cannot reach the server. Please check your internet connection.');
      }
      return ApiResponse.networkError('An unexpected error occurred. Please try again.');
    } catch (_) {
      return ApiResponse.networkError('An unexpected error occurred. Please try again.');
    }
  }
}

// ── Response wrapper ──────────────────────────────────────────────────────
class ApiResponse {
  final bool   success;
  final int    statusCode;
  final String message;
  final dynamic data;
  final dynamic errors;
  final bool   isNetworkError;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
    this.isNetworkError = false,
  });

  factory ApiResponse.networkError(String message) => ApiResponse(
    success: false, statusCode: 0, message: message, isNetworkError: true,
  );

  bool get isUnauthorized  => statusCode == 401;
  bool get isForbidden     => statusCode == 403;
  bool get isValidationErr => statusCode == 422;
  bool get isRateLimited   => statusCode == 429;
}
