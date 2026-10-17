import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/optimized_route.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/route_remote_datasource.dart';

/// Implementation of RouteRepository using remote data source
class RouteRepositoryImpl implements RouteRepository {
  final RouteRemoteDataSource remoteDataSource;
  final List<Stop> _stops = [];

  RouteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<Stop>> addStop(Stop stop) async {
    try {
      _stops.add(stop);
      return Result.success(stop);
    } catch (e) {
      return Result.failure(
        StorageFailure('Failed to add stop: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> removeStop(String stopId) async {
    try {
      _stops.removeWhere((s) => s.id == stopId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        StorageFailure('Failed to remove stop: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> clearStops() async {
    try {
      _stops.clear();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        StorageFailure('Failed to clear stops: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Stop>>> getStops() async {
    try {
      return Result.success(List.unmodifiable(_stops));
    } catch (e) {
      return Result.failure(
        StorageFailure('Failed to get stops: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<OptimizedRoute>> optimizeRoute() async {
    try {
      if (_stops.length < 2) {
        return Result.failure(
          RouteOptimizationFailure('At least 2 stops are required for optimization'),
        );
      }

      final coordinates = _stops.map((s) => s.coordinates).toList();
      final route = await remoteDataSource.optimizeRoute(coordinates);
      
      // Reorder stops based on optimization
      final reorderedStops = <Stop>[];
      for (final index in route.waypointOrder) {
        if (index < _stops.length) {
          reorderedStops.add(_stops[index]);
        }
      }
      
      // Update internal state
      _stops.clear();
      _stops.addAll(reorderedStops);

      return Result.success(route);
    } on RouteOptimizationException catch (e) {
      return Result.failure(
        RouteOptimizationFailure(e.message),
      );
    } on ApiException catch (e) {
      return Result.failure(
        ApiFailure(
          statusCode: e.statusCode,
          message: e.message,
          exception: e,
        ),
      );
    } on NetworkException catch (e) {
      return Result.failure(
        NetworkFailure(e.message),
      );
    } catch (e) {
      return Result.failure(
        RouteOptimizationFailure('Route optimization failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<bool> canOptimize() async {
    return _stops.length >= 2;
  }
}
