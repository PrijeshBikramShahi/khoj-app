// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_optimizer/core/error/failures.dart';
import 'package:route_optimizer/core/error/result.dart';
import 'package:route_optimizer/features/route/domain/entities/stop.dart';

void main() {
  test('validates route stops against geographic bounds', () {
    final kathmandu = Stop(
      id: 'kathmandu',
      coordinates: const LatLng(27.7172, 85.3240),
    );
    final impossible = Stop(
      id: 'invalid',
      coordinates: const LatLng(95, 200),
    );

    expect(kathmandu.isValid, isTrue);
    expect(impossible.isValid, isFalse);
  });

  test('fold exposes exactly one result branch', () {
    const success = Result<int>.success(3);
    final failure = Result<int>.failure(ValidationFailure('invalid stop'));

    expect(success.fold((_) => -1, (value) => value * 2), 6);
    expect(failure.fold((error) => error.message, (_) => 'ok'), 'invalid stop');
  });
}
