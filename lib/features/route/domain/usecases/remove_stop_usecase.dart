import '../repositories/route_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Use case for removing a stop from the route
class RemoveStopUseCase {
  final RouteRepository repository;

  RemoveStopUseCase(this.repository);

  /// Executes the use case to remove a stop
  /// 
  /// [stopId] The ID of the stop to remove
  /// Returns [Result<void>] indicating success or failure
  Future<Result<void>> call(String stopId) async {
    try {
      return await repository.removeStop(stopId);
    } catch (e) {
      return Result.failure(
        RouteOptimizationFailure('Failed to remove stop: ${e.toString()}'),
      );
    }
  }
}
