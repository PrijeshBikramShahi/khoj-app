import '../entities/optimized_route.dart';
import '../repositories/route_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Use case for optimizing the route
class OptimizeRouteUseCase {
  final RouteRepository repository;

  OptimizeRouteUseCase(this.repository);

  /// Executes the use case to optimize the route
  /// 
  /// Returns [Result<OptimizedRoute>] with the optimized route or a failure
  Future<Result<OptimizedRoute>> call() async {
    try {
      return await repository.optimizeRoute();
    } catch (e) {
      return Result.failure(
        RouteOptimizationFailure('Failed to optimize route: ${e.toString()}'),
      );
    }
  }
}
