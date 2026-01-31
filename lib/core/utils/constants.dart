/// Application constants and configuration
class AppConstants {
  /// App metadata
  static const String appName = 'Route Optimizer';
  static const String packageName = 'com.example.route_optimizer';
  static const String version = '1.0.0';

  /// API endpoints
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String osrmBaseUrl = 'https://router.project-osrm.org';

  /// API configuration
  static const String userAgent = 'RouteOptimizerApp/1.0';
  static const int apiTimeout = 30000; // 30 seconds

  /// Map configuration
  static const double defaultZoomLevel = 12.0;
  static const double maxZoomLevel = 19.0;
  static const double minZoomLevel = 1.0;
  
  /// Default location (Kathmandu, Nepal)
  static const double defaultLatitude = 27.689061;
  static const double defaultLongitude = 85.332337;

  /// Route optimization
  static const int maxStops = 100;
  static const double maxDistanceKm = 1000.0; // 1000 km limit
  static const double earthRadiusKm = 6371.0;

  /// Storage keys
  static const String storageKeyRouteHistory = 'route_history';
  static const String storageKeySettings = 'app_settings';
  static const String storageKeyLastLocation = 'last_location';

  /// Validation
  static const int minAddressLength = 2;
  static const int maxAddressLength = 200;
  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;
}

/// Error messages
class ErrorMessages {
  static const String networkError = 'Network connection failed. Please check your internet connection.';
  static const String apiError = 'Server error occurred. Please try again later.';
  static const String geocodingError = 'Could not find location. Please try a different address.';
  static const String routeOptimizationError = 'Could not calculate route. Please try again.';
  static const String storageError = 'Could not save data. Please try again.';
  static const String validationError = 'Invalid input. Please check your data.';
  static const String unknownError = 'An unexpected error occurred.';
}

/// Success messages
class SuccessMessages {
  static const String routeOptimized = 'Route optimized successfully!';
  static const String stopAdded = 'Stop added successfully!';
  static const String stopRemoved = 'Stop removed successfully!';
  static const String routeCleared = 'All stops cleared!';
}