import 'package:latlong2/latlong.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

/// Abstract interface for geocoding operations
/// Defines the contract that data layer implementations must follow
abstract class GeocodingRepository {
  /// Converts address string to coordinates
  /// 
  /// [address] The address to geocode
  /// Returns [Result<LatLng>] with the coordinates or a failure
  Future<Result<LatLng>> geocode(String address);

  /// Reverse geocodes coordinates to address
  /// 
  /// [coordinates] The coordinates to reverse geocode
  /// Returns [Result<String>] with the address or a failure
  Future<Result<String>> reverseGeocode(LatLng coordinates);
}