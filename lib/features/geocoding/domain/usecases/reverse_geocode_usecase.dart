import 'package:latlong2/latlong.dart';
import '../repositories/geocoding_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Use case for reverse geocoding coordinates to an address
class ReverseGeocodeUseCase {
  final GeocodingRepository repository;

  ReverseGeocodeUseCase(this.repository);

  /// Executes the use case to reverse geocode coordinates
  /// 
  /// [coordinates] The coordinates to reverse geocode
  /// Returns [Result<String>] with the address or a failure
  Future<Result<String>> call(LatLng coordinates) async {
    try {
      return await repository.reverseGeocode(coordinates);
    } catch (e) {
      return Result.failure(
        GeocodingFailure('Failed to reverse geocode: ${e.toString()}'),
      );
    }
  }
}
