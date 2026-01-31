import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(const RouteOptimizerApp());
}

class RouteOptimizerApp extends StatelessWidget {
  const RouteOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RouteState(),
      child: MaterialApp(
        title: 'Route Optimizer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const MapScreen(),
      ),
    );
  }
}

// ============================================================================
// MODELS
// ============================================================================

/// Represents a stop in the route with location and optional address
class Stop {
  final String id;
  final LatLng coordinates;
  final String? address;

  Stop({
    required this.id,
    required this.coordinates,
    this.address,
  });

  Stop copyWith({String? address}) {
    return Stop(
      id: id,
      coordinates: coordinates,
      address: address ?? this.address,
    );
  }
}

/// Route optimization result from OSRM
class OptimizedRoute {
  final List<LatLng> polyline;
  final double distanceKm;
  final double durationMinutes;
  final List<int> waypointOrder;

  OptimizedRoute({
    required this.polyline,
    required this.distanceKm,
    required this.durationMinutes,
    required this.waypointOrder,
  });
}

// ============================================================================
// SERVICES
// ============================================================================

/// Service for geocoding addresses to coordinates using Nominatim
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Convert address string to coordinates
  Future<LatLng?> geocode(String address) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': '1',
        },
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'RouteOptimizerApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return null;
  }

  /// Reverse geocode coordinates to address
  Future<String?> reverseGeocode(LatLng coordinates) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse').replace(
        queryParameters: {
          'lat': coordinates.latitude.toString(),
          'lon': coordinates.longitude.toString(),
          'format': 'json',
        },
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'RouteOptimizerApp/1.0'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['display_name'];
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return null;
  }
}

/// Service for route optimization using OSRM
class RoutingService {
  static const String _baseUrl = 'http://router.project-osrm.org';

  /// Optimize route for multiple stops using OSRM Trip API
  Future<OptimizedRoute?> optimizeRoute(List<LatLng> stops) async {
    if (stops.length < 2) return null;

    try {
      // Build coordinates string: lon,lat;lon,lat;...
      final coordinates =
          stops.map((s) => '${s.longitude},${s.latitude}').join(';');

      final uri = Uri.parse('$_baseUrl/trip/v1/driving/$coordinates').replace(
        queryParameters: {
          'source': 'first', // Start from first waypoint
          'destination': 'last', // End at last waypoint
          'roundtrip': 'false',
          'geometries': 'geojson',
          'overview': 'full',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['trips'] != null &&
            data['trips'].isNotEmpty) {
          final trip = data['trips'][0];

          // Decode polyline from GeoJSON
          final geometry = trip['geometry']['coordinates'] as List;
          final polyline = geometry
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
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
        }
      }
    } catch (e) {
      debugPrint('Routing error: $e');
    }
    return null;
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
    return 12742 * asin(sqrt(a1)); // 2 * R; R = 6371 km
  }
}

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

class RouteState extends ChangeNotifier {
  final GeocodingService _geocodingService = GeocodingService();
  final RoutingService _routingService = RoutingService();

  List<Stop> _stops = [];
  OptimizedRoute? _optimizedRoute;
  bool _isLoading = false;
  String? _errorMessage;

  List<Stop> get stops => List.unmodifiable(_stops);
  OptimizedRoute? get optimizedRoute => _optimizedRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canOptimize => _stops.length >= 2;

  /// Add stop by address (geocoded)
  Future<void> addStopByAddress(String address) async {
    _setLoading(true);
    _clearError();

    final coordinates = await _geocodingService.geocode(address);

    if (coordinates != null) {
      final stop = Stop(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        coordinates: coordinates,
        address: address,
      );
      _stops.add(stop);
      _optimizedRoute = null; // Clear previous route
      notifyListeners();
    } else {
      _setError('Could not find location for: $address');
    }

    _setLoading(false);
  }

  /// Add stop by coordinates
  Future<void> addStopByCoordinates(LatLng coordinates) async {
    final stop = Stop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coordinates: coordinates,
    );
    _stops.add(stop);
    _optimizedRoute = null;

    // Optionally reverse geocode in background
    _geocodingService.reverseGeocode(coordinates).then((address) {
      if (address != null) {
        final index = _stops.indexWhere((s) => s.id == stop.id);
        if (index != -1) {
          _stops[index] = stop.copyWith(address: address);
          notifyListeners();
        }
      }
    });

    notifyListeners();
  }

  /// Remove stop by ID
  void removeStop(String stopId) {
    _stops.removeWhere((s) => s.id == stopId);
    _optimizedRoute = null;
    notifyListeners();
  }

  /// Clear all stops
  void clearStops() {
    _stops.clear();
    _optimizedRoute = null;
    notifyListeners();
  }

  /// Calculate optimized route
  Future<void> calculateOptimizedRoute() async {
    if (!canOptimize) return;

    _setLoading(true);
    _clearError();

    final coordinates = _stops.map((s) => s.coordinates).toList();
    final route = await _routingService.optimizeRoute(coordinates);

    if (route != null) {
      _optimizedRoute = route;

      // Reorder stops based on optimization
      final reorderedStops = <Stop>[];
      for (final index in route.waypointOrder) {
        if (index < _stops.length) {
          reorderedStops.add(_stops[index]);
        }
      }
      _stops = reorderedStops;
    } else {
      _setError('Could not calculate route. Please try again.');
    }

    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

// ============================================================================
// UI SCREENS
// ============================================================================

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _addStopFromInput(RouteState state) {
    final input = _addressController.text.trim();
    if (input.isEmpty) return;

    // Check if input is coordinates (lat,lon format)
    final coordPattern = RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$');
    if (coordPattern.hasMatch(input)) {
      final parts = input.split(',').map((s) => s.trim()).toList();
      final lat = double.tryParse(parts[0]);
      final lon = double.tryParse(parts[1]);

      if (lat != null && lon != null) {
        state.addStopByCoordinates(LatLng(lat, lon));
        _addressController.clear();
        return;
      }
    }

    // Treat as address
    state.addStopByAddress(input);
    _addressController.clear();
  }

  void _fitBounds(RouteState state) {
    if (state.stops.isEmpty) return;

    final coordinates = state.stops.map((s) => s.coordinates).toList();
    if (state.optimizedRoute != null) {
      coordinates.addAll(state.optimizedRoute!.polyline);
    }

    final bounds = LatLngBounds.fromPoints(coordinates);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Optimizer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<RouteState>(
        builder: (context, state, _) {
          // Auto-fit bounds when route is calculated
          if (state.optimizedRoute != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitBounds(state);
            });
          }

          return Column(
            children: [
              // Map
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            const LatLng(27.689061, 85.332337), // NYC
                        initialZoom: 12,
                        onTap: (_, point) {
                          state.addStopByCoordinates(point);
                        },
                      ),
                      children: [
                        // OSM Tiles
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.route_optimizer',
                          maxZoom: 19,
                        ),

                        // Route Polyline
                        if (state.optimizedRoute != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: state.optimizedRoute!.polyline,
                                color: Colors.blue,
                                strokeWidth: 4,
                              ),
                            ],
                          ),

                        // Stop Markers
                        MarkerLayer(
                          markers: state.stops.asMap().entries.map((entry) {
                            final index = entry.key;
                            final stop = entry.value;
                            return Marker(
                              point: stop.coordinates,
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () =>
                                    _showStopOptions(context, state, stop),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: index == 0
                                        ? Colors.green
                                        : index == state.stops.length - 1
                                            ? Colors.red
                                            : Colors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Loading Indicator
                    if (state.isLoading)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),

              // Controls Panel
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Input Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter address or lat,lon',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _addStopFromInput(state),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () => _addStopFromInput(state),
                              icon: const Icon(Icons.add_location),
                              tooltip: 'Add Stop',
                            ),
                          ],
                        ),
                      ),

                      // Error Message
                      if (state.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Route Info
                      if (state.optimizedRoute != null)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoChip(
                                Icons.straighten,
                                '${state.optimizedRoute!.distanceKm.toStringAsFixed(1)} km',
                              ),
                              _buildInfoChip(
                                Icons.access_time,
                                '${state.optimizedRoute!.durationMinutes.toStringAsFixed(0)} min',
                              ),
                              _buildInfoChip(
                                Icons.location_on,
                                '${state.stops.length} stops',
                              ),
                            ],
                          ),
                        ),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: state.canOptimize && !state.isLoading
                                    ? () => state.calculateOptimizedRoute()
                                    : null,
                                icon: const Icon(Icons.route),
                                label: const Text('Optimize Route'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              onPressed: state.stops.isNotEmpty
                                  ? () => state.clearStops()
                                  : null,
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Clear All',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Stops List
                      Expanded(
                        child: state.stops.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tap map or enter address to add stops',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: state.stops.length,
                                itemBuilder: (context, index) {
                                  final stop = state.stops[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: index == 0
                                            ? Colors.green
                                            : index == state.stops.length - 1
                                                ? Colors.red
                                                : Colors.orange,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        stop.address ?? 'Unknown location',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${stop.coordinates.latitude.toStringAsFixed(4)}, '
                                        '${stop.coordinates.longitude.toStringAsFixed(4)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () =>
                                            state.removeStop(stop.id),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
      ],
    );
  }

  void _showStopOptions(BuildContext context, RouteState state, Stop stop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stop.address ?? 'Unknown location'),
            const SizedBox(height: 8),
            Text(
              '${stop.coordinates.latitude.toStringAsFixed(6)}, '
              '${stop.coordinates.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.removeStop(stop.id);
            },
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
