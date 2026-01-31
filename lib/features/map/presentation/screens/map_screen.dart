import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/constants.dart';
import '../../../../features/route/domain/entities/stop.dart';
import '../../../../features/route/domain/entities/optimized_route.dart';
import '../viewmodels/map_viewmodel.dart';

/// Map screen using the new Clean Architecture with MVVM
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<MapViewModel>();
      viewModel.init();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _fitBounds(MapViewModel viewModel) {
    if (viewModel.stops.isEmpty) return;

    final coordinates = viewModel.stops.map((s) => s.coordinates).toList();
    if (viewModel.optimizedRoute != null) {
      coordinates.addAll(viewModel.optimizedRoute!.polyline);
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
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<MapViewModel>(
        builder: (context, viewModel, _) {
          // Auto-fit bounds when route is calculated
          if (viewModel.optimizedRoute != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitBounds(viewModel);
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
                        initialCenter: LatLng(
                          AppConstants.defaultLatitude,
                          AppConstants.defaultLongitude,
                        ),
                        initialZoom: AppConstants.defaultZoomLevel,
                        onTap: (_, point) {
                          viewModel.addStopByCoordinates(point);
                        },
                      ),
                      children: [
                        // OSM Tiles
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: AppConstants.packageName,
                          maxZoom: AppConstants.maxZoomLevel,
                        ),
                        
                        // Route Polyline
                        if (viewModel.optimizedRoute != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: viewModel.optimizedRoute!.polyline,
                                color: Colors.blue,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        
                        // Stop Markers
                        MarkerLayer(
                          markers: viewModel.stops.asMap().entries.map((entry) {
                            final index = entry.key;
                            final stop = entry.value;
                            return Marker(
                              point: stop.coordinates,
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showStopOptions(context, viewModel, stop),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: index == 0
                                        ? Colors.green
                                        : index == viewModel.stops.length - 1
                                            ? Colors.red
                                            : Colors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
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
                    if (viewModel.isLoading)
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
                                onChanged: viewModel.setInputText,
                                onSubmitted: (_) => viewModel.addStopFromInput(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: viewModel.inputText.isNotBlank
                                  ? () => viewModel.addStopFromInput()
                                  : null,
                              icon: const Icon(Icons.add_location),
                              tooltip: 'Add Stop',
                            ),
                          ],
                        ),
                      ),

                      // Error Message
                      if (viewModel.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Route Info
                      if (viewModel.optimizedRoute != null)
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
                                viewModel.optimizedRoute!.formattedDistance,
                              ),
                              _buildInfoChip(
                                Icons.access_time,
                                viewModel.optimizedRoute!.formattedDuration,
                              ),
                              _buildInfoChip(
                                Icons.location_on,
                                '${viewModel.stops.length} stops',
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
                                onPressed: viewModel.canOptimize && !viewModel.isLoading
                                    ? () => viewModel.calculateOptimizedRoute()
                                    : null,
                                icon: const Icon(Icons.route),
                                label: const Text('Optimize Route'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              onPressed: viewModel.stops.isNotEmpty
                                  ? () => viewModel.clearStops()
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
                        child: viewModel.stops.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tap map or enter address to add stops',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: viewModel.stops.length,
                                itemBuilder: (context, index) {
                                  final stop = viewModel.stops[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: index == 0
                                            ? Colors.green
                                            : index == viewModel.stops.length - 1
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
                                        onPressed: () => viewModel.removeStop(stop.id),
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

  void _showStopOptions(BuildContext context, MapViewModel viewModel, Stop stop) {
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
              viewModel.removeStop(stop.id);
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