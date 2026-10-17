import 'package:latlong2/latlong.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/geocoding_repository.dart';
import '../datasources/geocoding_remote_datasource.dart';

/// Implementation of GeocodingRepository using remote data source
class GeocodingRepositoryImpl implements GeocodingRepository {
  final GeocodingRemoteDataSource remoteDataSource;

  GeocodingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<LatLng>> geocode(String address) async {
    try {
      final coordinates = await remoteDataSource.geocode(address);
      return Result.success(coordinates);
    } on GeocodingException catch (e) {
      return Result.failure(
        GeocodingFailure(e.message),
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
        GeocodingFailure('Geocoding failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<String>> reverseGeocode(LatLng coordinates) async {
    try {
      final address = await remoteDataSource.reverseGeocode(coordinates);
      return Result.success(address);
    } on GeocodingException catch (e) {
      return Result.failure(
        GeocodingFailure(e.message),
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
        GeocodingFailure('Reverse geocoding failed: ${e.toString()}'),
      );
    }
  }
}
