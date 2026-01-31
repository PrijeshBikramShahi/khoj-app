/// Base class for all application exceptions
abstract class RouteOptimizerException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  RouteOptimizerException(this.message, [this.stackTrace]);

  @override
  String toString() => 'RouteOptimizerException: $message';
}

/// Exception thrown when network operations fail
class NetworkException extends RouteOptimizerException {
  NetworkException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

/// Exception thrown when API returns error responses
class ApiException extends RouteOptimizerException {
  final int statusCode;
  final Map<String, dynamic>? response;

  ApiException({
    required this.statusCode,
    required String message,
    this.response,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() =>
      'ApiException(status: $statusCode, message: $message, response: $response)';
}

/// Exception thrown when geocoding operations fail
class GeocodingException extends RouteOptimizerException {
  GeocodingException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

/// Exception thrown when route optimization fails
class RouteOptimizationException extends RouteOptimizerException {
  RouteOptimizationException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}

/// Exception thrown when local storage operations fail
class StorageException extends RouteOptimizerException {
  StorageException(String message, [StackTrace? stackTrace])
      : super(message, stackTrace);
}