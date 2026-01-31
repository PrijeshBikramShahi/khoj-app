import '../../repositories/route_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Use case for clearing all stops from the route
class ClearStopsUseCase {
  final RouteRepository repository;

  ClearStopsUseCase(this.repository);

  /// Executes the use case to clear all stops
  /// 
  /// Returns [Result<void>] indicating success or failure
  Future<Result<void>> call() async {
    try {
      return await repository.clearStops();
    } catch (e) {
      return Result.failure(
        RouteOptimizationFailure('Failed to clear stops: ${e.toString()}'),
      );
    }
  }
}