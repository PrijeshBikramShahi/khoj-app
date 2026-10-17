import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/failures.dart';
import '../../../route/domain/entities/stop.dart';
import '../../../route/domain/entities/optimized_route.dart';
import '../../../route/domain/usecases/add_stop_usecase.dart';
import '../../../route/domain/usecases/clear_stops_usecase.dart';
import '../../../route/domain/usecases/get_stops_usecase.dart';
import '../../../route/domain/usecases/optimize_route_usecase.dart';
import '../../../route/domain/usecases/remove_stop_usecase.dart';
import '../../../geocoding/domain/usecases/geocode_usecase.dart';
import '../../../geocoding/domain/usecases/reverse_geocode_usecase.dart';

/// View model for the map screen
/// Handles all business logic and state management for the map UI
class MapViewModel extends ChangeNotifier {
  final AddStopUseCase _addStopUseCase;
  final RemoveStopUseCase _removeStopUseCase;
  final ClearStopsUseCase _clearStopsUseCase;
  final GetStopsUseCase _getStopsUseCase;
  final OptimizeRouteUseCase _optimizeRouteUseCase;
  final GeocodeUseCase _geocodeUseCase;
  final ReverseGeocodeUseCase _reverseGeocodeUseCase;

  // State variables
  List<Stop> _stops = [];
  OptimizedRoute? _optimizedRoute;
  bool _isLoading = false;
  String? _errorMessage;
  String _inputText = '';

  // Getters
  List<Stop> get stops => List.unmodifiable(_stops);
  OptimizedRoute? get optimizedRoute => _optimizedRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get inputText => _inputText;
  bool get canOptimize => _stops.length >= 2;

  MapViewModel({
    required AddStopUseCase addStopUseCase,
    required RemoveStopUseCase removeStopUseCase,
    required ClearStopsUseCase clearStopsUseCase,
    required GetStopsUseCase getStopsUseCase,
    required OptimizeRouteUseCase optimizeRouteUseCase,
    required GeocodeUseCase geocodeUseCase,
    required ReverseGeocodeUseCase reverseGeocodeUseCase,
  })  : _addStopUseCase = addStopUseCase,
        _removeStopUseCase = removeStopUseCase,
        _clearStopsUseCase = clearStopsUseCase,
        _getStopsUseCase = getStopsUseCase,
        _optimizeRouteUseCase = optimizeRouteUseCase,
        _geocodeUseCase = geocodeUseCase,
        _reverseGeocodeUseCase = reverseGeocodeUseCase;

  /// Initializes the view model
  Future<void> init() async {
    await _loadStops();
  }

  /// Loads stops from repository
  Future<void> _loadStops() async {
    final result = await _getStopsUseCase.call();
    result.fold(
      (failure) => _handleError(failure),
      (stops) => _stops = stops,
    );
    notifyListeners();
  }

  /// Adds a stop by address (geocoded)
  Future<void> addStopByAddress(String address) async {
    if (address.trim().isEmpty) return;

    _setLoading(true);
    _clearError();

    final result = await _geocodeUseCase.call(address);
    result.fold(
      (failure) => _handleError(failure),
      (coordinates) async {
        final stop = Stop(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          coordinates: coordinates,
          address: address,
        );
        
        final addResult = await _addStopUseCase.call(stop);
        addResult.fold(
          (failure) => _handleError(failure),
          (_) {
            _stops.add(stop);
            notifyListeners();
          },
        );
      },
    );

    _setLoading(false);
  }

  /// Adds a stop by coordinates
  Future<void> addStopByCoordinates(LatLng coordinates) async {
    _setLoading(true);
    _clearError();

    final stop = Stop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coordinates: coordinates,
    );

    final addResult = await _addStopUseCase.call(stop);
    addResult.fold(
      (failure) => _handleError(failure),
      (_) {
        _stops.add(stop);
        
        // Optionally reverse geocode in background
        _reverseGeocodeUseCase.call(coordinates).then((result) {
          result.fold(
            (failure) => null, // Ignore reverse geocoding errors
            (address) {
              final index = _stops.indexWhere((s) => s.id == stop.id);
              if (index != -1) {
                _stops[index] = stop.copyWith(address: address);
                notifyListeners();
              }
            },
          );
        });

        notifyListeners();
      },
    );

    _setLoading(false);
  }

  /// Removes a stop by ID
  Future<void> removeStop(String stopId) async {
    _setLoading(true);
    _clearError();

    final result = await _removeStopUseCase.call(stopId);
    result.fold(
      (failure) => _handleError(failure),
      (_) {
        _stops.removeWhere((s) => s.id == stopId);
        _optimizedRoute = null;
        notifyListeners();
      },
    );

    _setLoading(false);
  }

  /// Clears all stops
  Future<void> clearStops() async {
    _setLoading(true);
    _clearError();

    final result = await _clearStopsUseCase.call();
    result.fold(
      (failure) => _handleError(failure),
      (_) {
        _stops.clear();
        _optimizedRoute = null;
        notifyListeners();
      },
    );

    _setLoading(false);
  }

  /// Calculates optimized route
  Future<void> calculateOptimizedRoute() async {
    if (!canOptimize) return;

    _setLoading(true);
    _clearError();

    final result = await _optimizeRouteUseCase.call();
    result.fold(
      (failure) => _handleError(failure),
      (route) {
        _optimizedRoute = route;
        notifyListeners();
      },
    );

    _setLoading(false);
  }

  /// Handles input text changes
  void setInputText(String text) {
    _inputText = text;
    notifyListeners();
  }

  /// Adds stop from input text (address or coordinates)
  Future<void> addStopFromInput() async {
    final input = _inputText.trim();
    if (input.isEmpty) return;

    // Check if input is coordinates (lat,lon format)
    final coordPattern = RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$');
    if (coordPattern.hasMatch(input)) {
      final parts = input.split(',').map((s) => s.trim()).toList();
      final lat = double.tryParse(parts[0]);
      final lon = double.tryParse(parts[1]);

      if (lat != null && lon != null) {
        addStopByCoordinates(LatLng(lat, lon));
        setInputText('');
        return;
      }
    }

    // Treat as address
    addStopByAddress(input);
    setInputText('');
  }

  /// Sets loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Sets error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Handles errors from use cases
  void _handleError(RouteOptimizerFailure failure) {
    _setError(failure.message);
  }
}
