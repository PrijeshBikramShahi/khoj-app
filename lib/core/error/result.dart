import 'failures.dart';

/// A wrapper class for operations that can either succeed with a value or fail with an error
class Result<T> {
  final bool isSuccess;
  final T? _value;
  final RouteOptimizerFailure? _failure;

  /// Creates a successful result with a value
  const Result.success(T value)
      : isSuccess = true,
        _value = value,
        _failure = null;

  /// Creates a failed result with an error
  const Result.failure(RouteOptimizerFailure failure)
      : isSuccess = false,
        _value = null,
        _failure = failure;

  /// Gets the value if the result is successful, otherwise throws an exception
  T get value {
    if (!isSuccess) {
      throw StateError('Cannot get value from a failed result');
    }
    return _value!;
  }

  /// Gets the failure if the result failed, otherwise throws an exception
  RouteOptimizerFailure get failure {
    if (isSuccess) {
      throw StateError('Cannot get failure from a successful result');
    }
    return _failure!;
  }

  /// Maps the value if successful, otherwise returns the same failure
  Result<R> map<R>(R Function(T value) mapper) {
    if (isSuccess) {
      try {
        return Result.success(mapper(_value!));
      } catch (e) {
        return Result.failure(
          ApiFailure(
            statusCode: 500,
            message: 'Mapping failed: ${e.toString()}',
          ),
        );
      }
    } else {
      return Result.failure(_failure!) as Result<R>;
    }
  }

  /// Maps the failure if failed, otherwise returns the same success
  Result<T> mapFailure(RouteOptimizerFailure Function(RouteOptimizerFailure failure) mapper) {
    if (!isSuccess) {
      return Result.failure(mapper(_failure!));
    } else {
      return Result.success(_value!);
    }
  }

  /// Chains operations that return Results
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    if (isSuccess) {
      try {
        return mapper(_value!);
      } catch (e) {
        return Result.failure(
          ApiFailure(
            statusCode: 500,
            message: 'Chaining failed: ${e.toString()}',
          ),
        );
      }
    } else {
      return Result.failure(_failure!) as Result<R>;
    }
  }

  /// Executes a function if successful, otherwise returns the same failure
  Result<T> onSuccess(void Function(T value) action) {
    if (isSuccess) {
      action(_value!);
    }
    return this;
  }

  /// Executes a function if failed, otherwise returns the same success
  Result<T> onFailure(void Function(RouteOptimizerFailure failure) action) {
    if (!isSuccess) {
      action(_failure!);
    }
    return this;
  }

  /// Returns a default value if the result failed
  T getOrElse(T defaultValue) {
    return isSuccess ? _value! : defaultValue;
  }

  /// Returns a computed default value if the result failed
  T getOrElseCompute(T Function() defaultValue) {
    return isSuccess ? _value! : defaultValue();
  }

  /// Handles both result states without exposing nullable internals.
  R fold<R>(
    R Function(RouteOptimizerFailure failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    return isSuccess ? onSuccess(value) : onFailure(failure);
  }

  @override
  String toString() {
    return isSuccess ? 'Result.success($_value)' : 'Result.failure($_failure)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Result<T> &&
        other.isSuccess == isSuccess &&
        other._value == _value &&
        other._failure == _failure;
  }

  @override
  int get hashCode {
    return Object.hash(isSuccess, _value, _failure);
  }
}

/// Extension methods for Result to make it more convenient to use
extension ResultExtensions<T> on Result<T> {
  /// Converts a nullable value to a Result
  static Result<T> fromNullable<T>(T? value, String errorMessage) {
    return value != null
        ? Result.success(value)
        : Result.failure(ValidationFailure(errorMessage));
  }

  /// Converts a function that might throw to a Result
  static Result<T> fromTry<T>(T Function() operation, String errorMessage) {
    try {
      final result = operation();
      return Result.success(result);
    } catch (e) {
      return Result.failure(
        ApiFailure(
          statusCode: 500,
          message: '$errorMessage: ${e.toString()}',
        ),
      );
    }
  }

  /// Converts a Future to a Result
  static Future<Result<T>> fromFuture<T>(Future<T> future, String errorMessage) async {
    try {
      final result = await future;
      return Result.success(result);
    } catch (e) {
      return Result.failure(
        NetworkFailure('$errorMessage: ${e.toString()}'),
      );
    }
  }
}
