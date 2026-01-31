import 'package:latlong2/latlong.dart';

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

  /// Validates the route data
  bool get isValid {
    return polyline.isNotEmpty &&
        distanceKm >= 0.0 &&
        durationMinutes >= 0.0 &&
        waypointOrder.length == polyline.length;
  }

  /// Gets the formatted distance string
  String get formattedDistance {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Gets the formatted duration string
  String get formattedDuration {
    if (durationMinutes < 60.0) {
      return '${durationMinutes.toStringAsFixed(0)} min';
    } else {
      final hours = (durationMinutes / 60).floor();
      final minutes = (durationMinutes % 60).round();
      return '${hours}h ${minutes}m';
    }
  }

  @override
  String toString() {
    return 'OptimizedRoute(distance: $distanceKm km, duration: $durationMinutes min, stops: ${waypointOrder.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OptimizedRoute &&
        other.polyline == polyline &&
        other.distanceKm == distanceKm &&
        other.durationMinutes == durationMinutes &&
        other.waypointOrder == waypointOrder;
  }

  @override
  int get hashCode {
    return Object.hash(polyline, distanceKm, durationMinutes, waypointOrder);
  }
}