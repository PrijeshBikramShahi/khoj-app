import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'features/geocoding/data/datasources/geocoding_remote_datasource.dart';
import 'features/geocoding/data/repositories/geocoding_repository_impl.dart';
import 'features/geocoding/domain/repositories/geocoding_repository.dart';
import 'features/geocoding/domain/usecases/geocode_usecase.dart';
import 'features/geocoding/domain/usecases/reverse_geocode_usecase.dart';
import 'features/route/data/datasources/route_remote_datasource.dart';
import 'features/route/data/repositories/route_repository_impl.dart';
import 'features/route/domain/repositories/route_repository.dart';
import 'features/route/domain/usecases/add_stop_usecase.dart';
import 'features/route/domain/usecases/clear_stops_usecase.dart';
import 'features/route/domain/usecases/get_stops_usecase.dart';
import 'features/route/domain/usecases/optimize_route_usecase.dart';
import 'features/route/domain/usecases/remove_stop_usecase.dart';
import 'features/map/presentation/viewmodels/map_viewmodel.dart';

/// Dependency injection container
/// Manages the creation and lifecycle of all dependencies
class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  /// List of providers for the app
  List<SingleChildWidget> get providers => [
        // Core dependencies
        Provider<http.Client>(
          create: (_) => http.Client(),
          dispose: (_, client) => client.close(),
        ),

        // Data sources
        Provider<RouteRemoteDataSource>(
          create: (context) => RouteRemoteDataSource(
            httpClient: context.read<http.Client>(),
          ),
        ),
        Provider<GeocodingRemoteDataSource>(
          create: (context) => GeocodingRemoteDataSource(
            httpClient: context.read<http.Client>(),
          ),
        ),

        // Repositories
        Provider<RouteRepository>(
          create: (context) => RouteRepositoryImpl(
            remoteDataSource: context.read<RouteRemoteDataSource>(),
          ),
        ),
        Provider<GeocodingRepository>(
          create: (context) => GeocodingRepositoryImpl(
            remoteDataSource: context.read<GeocodingRemoteDataSource>(),
          ),
        ),

        // Use cases
        Provider<AddStopUseCase>(
          create: (context) => AddStopUseCase(
            context.read<RouteRepository>(),
          ),
        ),
        Provider<RemoveStopUseCase>(
          create: (context) => RemoveStopUseCase(
            context.read<RouteRepository>(),
          ),
        ),
        Provider<ClearStopsUseCase>(
          create: (context) => ClearStopsUseCase(
            context.read<RouteRepository>(),
          ),
        ),
        Provider<GetStopsUseCase>(
          create: (context) => GetStopsUseCase(
            context.read<RouteRepository>(),
          ),
        ),
        Provider<OptimizeRouteUseCase>(
          create: (context) => OptimizeRouteUseCase(
            context.read<RouteRepository>(),
          ),
        ),
        Provider<GeocodeUseCase>(
          create: (context) => GeocodeUseCase(
            context.read<GeocodingRepository>(),
          ),
        ),
        Provider<ReverseGeocodeUseCase>(
          create: (context) => ReverseGeocodeUseCase(
            context.read<GeocodingRepository>(),
          ),
        ),

        // View models
        ChangeNotifierProvider<MapViewModel>(
          create: (context) => MapViewModel(
            addStopUseCase: context.read<AddStopUseCase>(),
            removeStopUseCase: context.read<RemoveStopUseCase>(),
            clearStopsUseCase: context.read<ClearStopsUseCase>(),
            getStopsUseCase: context.read<GetStopsUseCase>(),
            optimizeRouteUseCase: context.read<OptimizeRouteUseCase>(),
            geocodeUseCase: context.read<GeocodeUseCase>(),
            reverseGeocodeUseCase: context.read<ReverseGeocodeUseCase>(),
          ),
        ),
      ];

  /// Initializes the dependency injection container
  Future<void> init() async {
    // Any initialization logic can go here
  }
}
