import '../entities/stop.dart';
import '../repositories/route_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Use case for getting all stops from the route
class GetStopsUseCase {
  final RouteRepository repository;

  GetStopsUseCase(this.repository);

  /// Executes the use case to get all stops
  /// 
  /// Returns [Result<List<Stop>>] with the list of stops or a failure
  Future<Result<List<Stop>>> call() async {
    try {
      return await repository.getStops();
    } catch (e) {
      return Result.failure(
        RouteOptimizationFailure('Failed to get stops: ${e.toString()}'),
      );
    }
  }
}
