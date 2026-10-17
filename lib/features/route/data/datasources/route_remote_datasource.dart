import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/optimized_route.dart';

/// Remote data source for route operations using OSRM API
class RouteRemoteDataSource {
  final http.Client httpClient;

  RouteRemoteDataSource({required this.httpClient});

  /// Optimizes route for multiple stops using OSRM Trip API
  Future<OptimizedRoute> optimizeRoute(List<LatLng> stops) async {
    if (stops.length < 2) {
      throw RouteOptimizationException('At least 2 stops are required for optimization');
    }

    try {
      // Build coordinates string: lon,lat;lon,lat;...
      final coordinates = stops
          .map((s) => '${s.longitude},${s.latitude}')
          .join(';');

      final uri = Uri.parse('${AppConstants.osrmBaseUrl}/trip/v1/driving/$coordinates').replace(
        queryParameters: {
          'source': 'first',
          'destination': 'last',
          'roundtrip': 'false',
          'geometries': 'geojson',
          'overview': 'full',
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
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['trips'] != null && data['trips'].isNotEmpty) {
          final trip = data['trips'][0];
          
          // Decode polyline from GeoJSON with proper type handling
          final geometry = trip['geometry']['coordinates'] as List;
          final polyline = geometry
              .map((coord) => LatLng(
                  (coord[1] is int) ? (coord[1] as int).toDouble() : coord[1] as double,
                  (coord[0] is int) ? (coord[0] as int).toDouble() : coord[0] as double,
              ))
              .toList();

          // Get waypoint order
          final waypointOrder = (data['waypoints'] as List)
              .map((wp) => wp['waypoint_index'] as int)
              .toList();

          return OptimizedRoute(
            polyline: polyline,
            distanceKm: trip['distance'] / 1000.0,
            durationMinutes: trip['duration'] / 60.0,
            waypointOrder: waypointOrder,
          );
        } else {
          throw RouteOptimizationException('OSRM API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'OSRM API request failed',
          response: json.decode(response.body),
        );
      }
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw RouteOptimizationException('Route optimization failed: ${e.toString()}');
    }
  }

  /// Fallback: Simple TSP heuristic (Nearest Neighbor) for offline optimization
  List<int> nearestNeighborTSP(List<LatLng> stops) {
    if (stops.length <= 2) return List.generate(stops.length, (i) => i);

    final visited = <bool>[true] + List.filled(stops.length - 1, false);
    final route = <int>[0];
    int current = 0;

    for (int i = 1; i < stops.length; i++) {
      double minDist = double.infinity;
      int nearest = -1;

      for (int j = 1; j < stops.length; j++) {
        if (!visited[j]) {
          final dist = _distance(stops[current], stops[j]);
          if (dist < minDist) {
            minDist = dist;
            nearest = j;
          }
        }
      }

      if (nearest != -1) {
        visited[nearest] = true;
        route.add(nearest);
        current = nearest;
      }
    }

    return route;
  }

  double _distance(LatLng a, LatLng b) {
    const p = 0.017453292519943295; // Math.PI / 180
    final lat1 = a.latitude * p;
    final lat2 = b.latitude * p;
    final dLat = lat2 - lat1;
    final dLon = (b.longitude - a.longitude) * p;
    final a1 = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return AppConstants.earthRadiusKm * asin(sqrt(a1));
  }
}
