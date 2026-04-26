// lib/core/errors/failures.dart
// Failures are the presentation-safe wrapper around exceptions.
// Repositories catch exceptions and return Failures instead, so the UI
// never needs to handle raw exceptions.

abstract class Failure {
  final String message;
  const Failure(this.message);
  @override String toString() => '$runtimeType: $message';
}

/// HTTP / API error from the server (non-2xx response).
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, [this.statusCode]);
}

/// No internet connection or DNS / socket error.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// 401 — token expired or invalid credentials.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired. Please log in again.']);
}

/// 422 — form validation rejected by the server.
class ValidationFailure extends Failure {
  final Map<String, dynamic> errors;
  const ValidationFailure(super.message, this.errors);
  String get firstError =>
      errors.values.isNotEmpty ? errors.values.first.toString() : message;
}

/// SharedPreferences / SecureStorage read/write error.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error.']);
}

/// Device permission (camera, location, notifications) was denied.
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied.']);
}

/// Generic fallback for unexpected errors.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
