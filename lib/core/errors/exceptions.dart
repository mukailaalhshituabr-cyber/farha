// lib/core/errors/exceptions.dart

class ServerException implements Exception {
  final String message;
  final int?   statusCode;
  const ServerException(this.message, [this.statusCode]);
  @override String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection. Please check your network.']);
  @override String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Session expired. Please log in again.']);
  @override String toString() => 'UnauthorizedException: $message';
}

class ValidationException implements Exception {
  final Map<String, dynamic> errors;
  final String message;
  const ValidationException(this.message, this.errors);
  String get firstError => errors.values.isNotEmpty ? errors.values.first.toString() : message;
  @override String toString() => 'ValidationException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local storage error.']);
}

class PermissionException implements Exception {
  final String message;
  const PermissionException([this.message = 'Permission denied.']);
}
