// ignore_for_file: annotate_overrides

/// Result type for handling success and error cases in API operations
sealed class Result<T, E> {
  const Result();

  /// Creates a successful result
  factory Result.success(T value) = Success<T, E>;

  /// Creates an error result
  factory Result.error(E error) = Error<T, E>;

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this is an error result
  bool get isError => this is Error<T, E>;

  /// Gets the success value, throws if this is an error
  T get value => switch (this) {
        Success(value: final v) => v,
        Error() => throw StateError('Cannot get value from error result'),
      };

  /// Gets the error value, throws if this is a success
  E get error => switch (this) {
        Success() => throw StateError('Cannot get error from success result'),
        Error(error: final e) => e,
      };
}

/// Success case of Result
class Success<T, E> extends Result<T, E> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

/// Error case of Result
class Error<T, E> extends Result<T, E> {
  final E error;

  const Error(this.error);

  @override
  String toString() => 'Error($error)';
}