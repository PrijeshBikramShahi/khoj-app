import '../../entities/stop.dart';
import '../../entities/optimized_route.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Abstract interface for route operations
/// Defines the contract that data layer implementations must follow
abstract class RouteRepository {
  /// Adds a stop to the current route
  /// 
  /// [stop] The stop to add
  /// Returns [Result<Stop>] with the added stop or a failure
  Future<Result<Stop>> addStop(Stop stop);

  /// Removes a stop from the current route by ID
  /// 
  /// [stopId] The ID of the stop to remove
  /// Returns [Result<void>] indicating success or failure
  Future<Result<void>> removeStop(String stopId);

  /// Clears all stops from the current route
  /// 
  /// Returns [Result<void>] indicating success or failure
  Future<Result<void>> clearStops();

  /// Gets all stops in the current route
  /// 
  /// Returns [Result<List<Stop>>] with the list of stops or a failure
  Future<Result<List<Stop>>> getStops();

  /// Optimizes the route for the current stops
  /// 
  /// Returns [Result<OptimizedRoute>] with the optimized route or a failure
  Future<Result<OptimizedRoute>> optimizeRoute();

  /// Checks if route optimization is possible (minimum 2 stops required)
  /// 
  /// Returns [bool] true if optimization is possible
  Future<bool> canOptimize();
}