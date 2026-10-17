# Khoj

**Plan a multi-stop journey and see the optimized route on an interactive map.**

Khoj is a Flutter route planner for errands, deliveries, and day trips with
several destinations. Add places, let the app choose an efficient visiting
order, and inspect the resulting route without relying on a proprietary map
SDK.

## What Khoj does

- Searches addresses and converts them into map coordinates.
- Accepts several stops in one trip.
- Reorders stops through OSRM's trip service.
- Draws the route, stops, and current map context with OpenStreetMap tiles.
- Reports invalid locations, network failures, and routing failures through a
  typed result model.

## How it works

Khoj uses `flutter_map` for the map, Nominatim for geocoding, and OSRM for route
optimization. Domain use cases are separated from HTTP data sources and the
Flutter presentation layer; Provider-backed view models connect them at
runtime. See [ARCHITECTURE_SUMMARY.md](ARCHITECTURE_SUMMARY.md) for the detailed
module map.

## Run locally

Install a current Flutter SDK, then:

```sh
flutter pub get
flutter run
```

The public Nominatim and OSRM endpoints require internet access and are subject
to their usage policies. For sustained or commercial use, configure services
with capacity and terms appropriate to your traffic.

## Verify the project

```sh
flutter analyze
flutter test
```

## Product boundaries

Khoj is a client-side demonstration. It does not provide accounts, saved route
history, offline maps, live traffic, or a service-level guarantee for the
public routing endpoints. The repository currently contains both the original
entry point and a newer layered entry point while the architecture migration is
completed.
