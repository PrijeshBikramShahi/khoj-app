import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import 'package:latlong2/latlong.dart';

/// Remote data source for geocoding operations using Nominatim API
class GeocodingRemoteDataSource {
  final http.Client httpClient;

  GeocodingRemoteDataSource({required this.httpClient});

  /// Converts address string to coordinates using Nominatim
  Future<LatLng> geocode(String address) async {
    if (address.trim().isEmpty) {
      throw GeocodingException('Address cannot be empty');
    }

    try {
      final uri = Uri.parse('${AppConstants.nominatimBaseUrl}/search').replace(
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': '1',
        },
      );

      final response = await httpClient.get(
        uri,
        headers: {'User-Agent': AppConstants.userAgent},
      ).timeout(
        Duration(milliseconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw NetworkException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          return LatLng(lat, lon);
        } else {
          throw GeocodingException('No results found for address: $address');
        }
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Geocoding API request failed',
          response: json.decode(response.body),
        );
      }
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw GeocodingException('Geocoding failed: ${e.toString()}');
    }
  }

  /// Reverse geocodes coordinates to address using Nominatim
  Future<String> reverseGeocode(LatLng coordinates) async {
    try {
      final uri = Uri.parse('${AppConstants.nominatimBaseUrl}/reverse').replace(
        queryParameters: {
          'lat': coordinates.latitude.toString(),
          'lon': coordinates.longitude.toString(),
          'format': 'json',
        },
      );

      final response = await httpClient.get(
        uri,
        headers: {'User-Agent': AppConstants.userAgent},
      ).timeout(
        Duration(milliseconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw NetworkException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['display_name'] ?? 'Unknown location';
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Reverse geocoding API request failed',
          response: json.decode(response.body),
        );
      }
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw GeocodingException('Reverse geocoding failed: ${e.toString()}');
    }
  }
}
