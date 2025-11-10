/// API-related exceptions and error types
sealed class ApiError {
  const ApiError();

  /// Network or connection error
  factory ApiError.network(String message) = NetworkError;

  /// HTTP error with status code
  factory ApiError.http(int statusCode, String message) = HttpError;

  /// Timeout error
  factory ApiError.timeout(String message) = TimeoutError;

  /// Parsing or serialization error
  factory ApiError.parsing(String message) = ParsingError;

  /// Unknown error
  factory ApiError.unknown(String message) = UnknownError;

  /// Authentication required error
  factory ApiError.unauthorized([String message]) = UnauthorizedError;

  /// Gets the error message
  String get message;
}

/// Network connection error
class NetworkError extends ApiError {
  @override
  final String message;

  const NetworkError(this.message);

  @override
  String toString() => 'NetworkError: $message';
}

/// HTTP error with status code
class HttpError extends ApiError {
  final int statusCode;

  @override
  final String message;

  const HttpError(this.statusCode, this.message);

  @override
  String toString() => 'HttpError($statusCode): $message';
}

/// Request timeout error
class TimeoutError extends ApiError {
  @override
  final String message;

  const TimeoutError(this.message);

  @override
  String toString() => 'TimeoutError: $message';
}

/// JSON parsing/serialization error
class ParsingError extends ApiError {
  @override
  final String message;

  const ParsingError(this.message);

  @override
  String toString() => 'ParsingError: $message';
}

/// Unknown or unexpected error
class UnknownError extends ApiError {
  @override
  final String message;

  const UnknownError(this.message);

  @override
  String toString() => 'UnknownError: $message';
}

/// Authentication required error
class UnauthorizedError extends ApiError {
  @override
  final String message;

  const UnauthorizedError([this.message = 'Authentication required']);

  @override
  String toString() => 'UnauthorizedError: $message';
}