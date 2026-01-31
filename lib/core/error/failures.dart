import 'exceptions.dart';

/// Base class for all application failures
abstract class RouteOptimizerFailure {
  final String message;
  final RouteOptimizerException? exception;

  RouteOptimizerFailure(this.message, [this.exception]);

  @override
  String toString() => 'RouteOptimizerFailure: $message';
}

/// Failure for network-related operations
class NetworkFailure extends RouteOptimizerFailure {
  NetworkFailure(String message, [RouteOptimizerException? exception])
      : super(message, exception);
}

/// Failure for API-related operations
class ApiFailure extends RouteOptimizerFailure {
  final int statusCode;

  ApiFailure({
    required this.statusCode,
    required String message,
    RouteOptimizerException? exception,
  }) : super(message, exception);
}

/// Failure for geocoding operations
class GeocodingFailure extends RouteOptimizerFailure {
  GeocodingFailure(String message, [RouteOptimizerException? exception])
      : super(message, exception);
}

/// Failure for route optimization operations
class RouteOptimizationFailure extends RouteOptimizerFailure {
  RouteOptimizationFailure(String message, [RouteOptimizerException? exception])
      : super(message, exception);
}

/// Failure for local storage operations
class StorageFailure extends RouteOptimizerFailure {
  StorageFailure(String message, [RouteOptimizerException? exception])
      : super(message, exception);
}

/// Failure for validation operations
class ValidationFailure extends RouteOptimizerFailure {
  ValidationFailure(String message, [RouteOptimizerException? exception])
      : super(message, exception);
}