import 'package:latlong2/latlong.dart';
import '../repositories/geocoding_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Use case for geocoding an address to coordinates
class GeocodeUseCase {
  final GeocodingRepository repository;

  GeocodeUseCase(this.repository);

  /// Executes the use case to geocode an address
  /// 
  /// [address] The address to geocode
  /// Returns [Result<LatLng>] with the coordinates or a failure
  Future<Result<LatLng>> call(String address) async {
    try {
      return await repository.geocode(address);
    } catch (e) {
      return Result.failure(
        GeocodingFailure('Failed to geocode address: ${e.toString()}'),
      );
    }
  }
}
