# Clean Architecture with MVVM - Route Optimizer

## Overview

This document describes the new Clean Architecture implementation with MVVM pattern for the Route Optimizer Flutter application. The architecture provides better separation of concerns, improved testability, and easier maintenance.

## Architecture Layers

### 1. Core Layer (`lib/core/`)

**Purpose**: Shared infrastructure and utilities used across all features.

**Components**:
- **Error Handling** (`error/`):
  - `exceptions.dart`: Base exception classes for different error types
  - `failures.dart`: Failure classes for error propagation
  - `result.dart`: Result wrapper for operations that can succeed or fail

- **Utilities** (`utils/`):
  - `constants.dart`: Application constants and configuration
  - `extensions.dart`: Extension methods for common types

### 2. Domain Layer (`lib/features/*/domain/`)

**Purpose**: Business logic and entities that are independent of any framework or external dependencies.

**Components**:
- **Entities** (`entities/`):
  - `Stop.dart`: Represents a stop in the route
  - `OptimizedRoute.dart`: Represents an optimized route result

- **Repositories** (`repositories/`):
  - `route_repository.dart`: Abstract interface for route operations
  - `geocoding_repository.dart`: Abstract interface for geocoding operations

- **Use Cases** (`usecases/`):
  - `add_stop_usecase.dart`: Handles adding stops
  - `remove_stop_usecase.dart`: Handles removing stops
  - `clear_stops_usecase.dart`: Handles clearing all stops
  - `get_stops_usecase.dart`: Handles retrieving stops
  - `optimize_route_usecase.dart`: Handles route optimization
  - `geocode_usecase.dart`: Handles address geocoding
  - `reverse_geocode_usecase.dart`: Handles reverse geocoding

### 3. Data Layer (`lib/features/*/data/`)

**Purpose**: Data sources and repository implementations that handle external dependencies.

**Components**:
- **Data Sources** (`datasources/`):
  - `route_remote_datasource.dart`: OSRM API integration
  - `geocoding_remote_datasource.dart`: Nominatim API integration

- **Repositories** (`repositories/`):
  - `route_repository_impl.dart`: Implementation of RouteRepository
  - `geocoding_repository_impl.dart`: Implementation of GeocodingRepository

### 4. Presentation Layer (`lib/features/*/presentation/`)

**Purpose**: UI components and state management using MVVM pattern.

**Components**:
- **View Models** (`viewmodels/`):
  - `map_viewmodel.dart`: Manages map screen state and business logic

- **Screens** (`screens/`):
  - `map_screen.dart`: Main map interface using the new architecture

### 5. Dependency Injection (`lib/injection_container.dart`)

**Purpose**: Centralized dependency management and injection.

**Components**:
- `InjectionContainer`: Manages creation and lifecycle of all dependencies

## Key Benefits

### 1. Separation of Concerns
- **Domain layer** contains pure business logic without framework dependencies
- **Data layer** handles external API calls and data persistence
- **Presentation layer** focuses solely on UI and user interactions
- **Core layer** provides shared utilities and error handling

### 2. Testability
- Each layer can be unit tested independently
- Use cases can be tested without UI components
- Repository interfaces allow for easy mocking
- View models can be tested without actual API calls

### 3. Maintainability
- Clear boundaries between layers
- Easy to add new features without affecting other layers
- Changes in one layer don't cascade to others
- Better code organization and readability

### 4. Reusability
- Business logic can be reused across different UI implementations
- Repository interfaces can be implemented with different data sources
- Use cases can be composed for complex operations

## Error Handling Strategy

The architecture implements a comprehensive error handling strategy:

1. **Exceptions**: Low-level errors from external dependencies
2. **Failures**: High-level business logic errors
3. **Results**: Type-safe success/failure wrapper for operations
4. **Error Propagation**: Structured error flow from data layer to presentation

## State Management

Uses Provider with MVVM pattern:
- **View Models**: Manage screen-specific state and business logic
- **ChangeNotifier**: Automatic UI updates when state changes
- **Dependency Injection**: Clean separation of concerns

## API Integration

### OSRM API (Route Optimization)
- **Endpoint**: `https://router.project-osrm.org/trip/v1/driving/`
- **Features**: Multi-stop route optimization, polyline decoding
- **Error Handling**: Network timeouts, API errors, coordinate validation

### Nominatim API (Geocoding)
- **Endpoint**: `https://nominatim.openstreetmap.org/`
- **Features**: Address to coordinates, coordinates to address
- **Error Handling**: Network timeouts, API errors, validation

## Migration from Monolithic Architecture

### Before (Monolithic)
- Single `main.dart` file (~1000 lines)
- Mixed UI, business logic, and services
- Direct API calls from UI components
- Limited error handling
- Difficult to test and maintain

### After (Clean Architecture)
- Organized project structure with clear layers
- Separated concerns and responsibilities
- Comprehensive error handling
- Testable components
- Easy to extend and maintain

## Usage

To run the new architecture:

1. Use `lib/main_new.dart` instead of `lib/main.dart`
2. All dependencies are automatically injected via `InjectionContainer`
3. The app uses the same UI but with improved architecture underneath

## Future Enhancements

The new architecture makes it easy to add:

1. **Local Storage**: Add local data sources for offline support
2. **Settings**: User preferences and configuration
3. **Route History**: Save and load previous routes
4. **Multiple Map Providers**: Easy to switch between map services
5. **Advanced Features**: Traffic data, alternative routes, etc.

## Testing Strategy

Recommended testing approach:

1. **Unit Tests**: Test individual use cases and entities
2. **Integration Tests**: Test repository implementations
3. **Widget Tests**: Test UI components with mocked dependencies
4. **End-to-End Tests**: Test complete user workflows

## Conclusion

The Clean Architecture with MVVM pattern provides a solid foundation for the Route Optimizer application. It improves code quality, maintainability, and testability while making it easier to add new features and fix bugs.