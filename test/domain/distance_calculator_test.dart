import 'package:flutter_test/flutter_test.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/utils/distance_calculator.dart';

void main() {
  group('DistanceCalculator', () {
    final now = DateTime.now();

    test('returns Right(0.0) for an empty list of location points', () {
      final result = DistanceCalculator.calculateTotalDistance([]);

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Should succeed'),
        (distance) => expect(distance, equals(0.0)),
      );
    });

    test('returns Right(0.0) for a single location point', () {
      final point = LocationPoint(
        id: 'p1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      final result = DistanceCalculator.calculateTotalDistance([point]);

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Should succeed'),
        (distance) => expect(distance, equals(0.0)),
      );
    });

    test('returns Right(0.0) for two identical location points', () {
      final point = LocationPoint(
        id: 'p1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      final result = DistanceCalculator.calculateTotalDistance([point, point]);

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Should succeed'),
        (distance) => expect(distance, equals(0.0)),
      );
    });

    test('calculates accurate distance in meters for known coordinate pairs', () {
      // Coordinate distance from (0, 0) to (0, 1) is ~111,319 meters on Equator
      final p1 = LocationPoint(
        id: 'p1',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: now,
      );
      final p2 = LocationPoint(
        id: 'p2',
        latitude: 0.0,
        longitude: 1.0,
        timestamp: now.add(const Duration(seconds: 2)),
      );

      final result = DistanceCalculator.calculateTotalDistance([p1, p2]);

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Should succeed'),
        (distance) {
          expect(distance, greaterThan(111000));
          expect(distance, lessThan(112000));
        },
      );
    });

    test('sums distance correctly across multiple chronological segments', () {
      final p1 = LocationPoint(
        id: 'p1',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: now,
      );
      final p2 = LocationPoint(
        id: 'p2',
        latitude: 0.0,
        longitude: 1.0,
        timestamp: now.add(const Duration(seconds: 2)),
      );
      final p3 = LocationPoint(
        id: 'p3',
        latitude: 1.0,
        longitude: 1.0,
        timestamp: now.add(const Duration(seconds: 4)),
      );

      final segment1Only = DistanceCalculator.calculateTotalDistance([p1, p2]);
      final segment2Only = DistanceCalculator.calculateTotalDistance([p2, p3]);
      final fullPath = DistanceCalculator.calculateTotalDistance([p1, p2, p3]);

      double seg1Distance = 0.0;
      double seg2Distance = 0.0;
      double fullDistance = 0.0;

      segment1Only.match((_) {}, (d) => seg1Distance = d);
      segment2Only.match((_) {}, (d) => seg2Distance = d);
      fullPath.match((_) {}, (d) => fullDistance = d);

      expect(fullDistance, closeTo(seg1Distance + seg2Distance, 0.001));
    });

    test('returns Left(DistanceCalculationFailure) when latitude exceeds valid range (> 90)', () {
      final p1 = LocationPoint(
        id: 'p1',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: now,
      );
      final p2 = LocationPoint(
        id: 'p2',
        latitude: 95.0,
        longitude: 0.0,
        timestamp: now.add(const Duration(seconds: 2)),
      );

      final result = DistanceCalculator.calculateTotalDistance([p1, p2]);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<DistanceCalculationFailure>());
          expect(failure.message, contains('Invalid latitude or longitude'));
        },
        (_) => fail('Should fail with DistanceCalculationFailure'),
      );
    });

    test('returns Left(DistanceCalculationFailure) when latitude is below valid range (< -90)', () {
      final p1 = LocationPoint(
        id: 'p1',
        latitude: -91.0,
        longitude: 0.0,
        timestamp: now,
      );
      final p2 = LocationPoint(
        id: 'p2',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: now.add(const Duration(seconds: 2)),
      );

      final result = DistanceCalculator.calculateTotalDistance([p1, p2]);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<DistanceCalculationFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('returns Left(DistanceCalculationFailure) when longitude exceeds valid range (> 180)', () {
      final p1 = LocationPoint(
        id: 'p1',
        latitude: 0.0,
        longitude: 185.0,
        timestamp: now,
      );
      final p2 = LocationPoint(
        id: 'p2',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: now.add(const Duration(seconds: 2)),
      );

      final result = DistanceCalculator.calculateTotalDistance([p1, p2]);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<DistanceCalculationFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('returns Left(DistanceCalculationFailure) when longitude is below valid range (< -180)', () {
      final p1 = LocationPoint(
        id: 'p1',
        latitude: 0.0,
        longitude: -181.0,
        timestamp: now,
      );
      final p2 = LocationPoint(
        id: 'p2',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: now.add(const Duration(seconds: 2)),
      );

      final result = DistanceCalculator.calculateTotalDistance([p1, p2]);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<DistanceCalculationFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('returns Left(DistanceCalculationFailure) when coordinates are NaN or infinite', () {
      final p1 = LocationPoint(
        id: 'p1',
        latitude: double.nan,
        longitude: 0.0,
        timestamp: now,
      );
      final p2 = LocationPoint(
        id: 'p2',
        latitude: 0.0,
        longitude: double.infinity,
        timestamp: now.add(const Duration(seconds: 2)),
      );

      final resultNaN = DistanceCalculator.calculateTotalDistance([p1, LocationPoint(id: 'a', latitude: 0, longitude: 0, timestamp: now)]);
      final resultInf = DistanceCalculator.calculateTotalDistance([p2, LocationPoint(id: 'a', latitude: 0, longitude: 0, timestamp: now)]);

      expect(resultNaN.isLeft(), isTrue);
      expect(resultInf.isLeft(), isTrue);
    });
  });
}
