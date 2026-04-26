// lib/core/network/api_interceptor.dart
// Logging interceptor — prints every request and response in debug mode.
// Added to Dio via ApiClient. No-op in release builds.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ [${options.method}] ${options.uri}');
      if (options.data != null) debugPrint('   body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← [${response.statusCode}] ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✗ [${err.type.name}] ${err.requestOptions.uri}: ${err.message}');
    }
    handler.next(err);
  }
}
