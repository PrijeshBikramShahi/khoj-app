import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'injection_container.dart';
import 'features/map/presentation/screens/map_screen.dart';

/// Main application using the new Clean Architecture with MVVM
void main() {
  runApp(const RouteOptimizerApp());
}

class RouteOptimizerApp extends StatelessWidget {
  const RouteOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: InjectionContainer().providers,
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