import '../../entities/stop.dart';
import '../../repositories/route_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Use case for adding a stop to the route
class AddStopUseCase {
  final RouteRepository repository;

  AddStopUseCase(this.repository);

  /// Executes the use case to add a stop
  /// 
  /// [stop] The stop to add
  /// Returns [Result<Stop>] with the added stop or a failure
  Future<Result<Stop>> call(Stop stop) async {
    try {
      if (!stop.isValid) {
        return Result.failure(
          ValidationFailure('Invalid stop data'),
        );
      }

      return await repository.addStop(stop);
    } catch (e) {
      return Result.failure(
        RouteOptimizationFailure('Failed to add stop: ${e.toString()}'),
      );
    }
  }
}