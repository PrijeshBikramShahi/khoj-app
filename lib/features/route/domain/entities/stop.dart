import 'package:latlong2/latlong.dart';

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

  /// Creates a copy of this stop with optional updated values
  Stop copyWith({String? id, LatLng? coordinates, String? address}) {
    return Stop(
      id: id ?? this.id,
      coordinates: coordinates ?? this.coordinates,
      address: address ?? this.address,
    );
  }

  /// Validates the stop data
  bool get isValid {
    return id.isNotEmpty &&
        coordinates.latitude >= -90.0 &&
        coordinates.latitude <= 90.0 &&
        coordinates.longitude >= -180.0 &&
        coordinates.longitude <= 180.0;
  }

  @override
  String toString() {
    return 'Stop(id: $id, coordinates: $coordinates, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Stop &&
        other.id == id &&
        other.coordinates == coordinates &&
        other.address == address;
  }

  @override
  int get hashCode {
    return Object.hash(id, coordinates, address);
  }
}