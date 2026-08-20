import 'package:flutter_test/flutter_test.dart';

import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/utils/location_point_filter.dart';

void main() {
  group('LocationPointFilter', () {
    final now = DateTime.now();
    const filter = LocationPointFilter(
      minMoveMeters: 15.0,
      maxJumpMeters: 200.0,
    );

    test('isPlausible validates coordinate ranges correctly', () {
      expect(LocationPointFilter.isPlausible(0.0, 0.0), isTrue);
      expect(LocationPointFilter.isPlausible(33.5138, 36.2765), isTrue);
      expect(LocationPointFilter.isPlausible(-90.0, 180.0), isTrue);

      expect(LocationPointFilter.isPlausible(91.0, 0.0), isFalse);
      expect(LocationPointFilter.isPlausible(-95.0, 0.0), isFalse);
      expect(LocationPointFilter.isPlausible(0.0, 181.0), isFalse);
      expect(LocationPointFilter.isPlausible(0.0, -185.0), isFalse);
      expect(LocationPointFilter.isPlausible(double.nan, 0.0), isFalse);
      expect(LocationPointFilter.isPlausible(0.0, double.infinity), isFalse);
    });

    test('filter drops non-plausible coordinate points', () {
      final valid = LocationPoint(id: '1', latitude: 0.0, longitude: 0.0, timestamp: now);
      final invalid = LocationPoint(id: '2', latitude: 99.0, longitude: 0.0, timestamp: now);

      final result = filter.filter([valid, invalid]);
      expect(result.length, equals(1));
      expect(result.first.id, equals('1'));
    });

    test('filter drops stationary jitter movements below minMoveMeters', () {
      final p1 = LocationPoint(id: '1', latitude: 33.513800, longitude: 36.276500, timestamp: now);
      // Extremely tiny jitter shift (< 1 meter)
      final p2 = LocationPoint(id: '2', latitude: 33.513801, longitude: 36.276501, timestamp: now.add(const Duration(seconds: 2)));
      // Significant move (~100 meters)
      final p3 = LocationPoint(id: '3', latitude: 33.514700, longitude: 36.276500, timestamp: now.add(const Duration(seconds: 10)));

      final result = filter.filter([p1, p2, p3]);

      expect(result.length, equals(2));
      expect(result[0].id, equals('1'));
      expect(result[1].id, equals('3'));
    });

    test('filter drops impossible coordinate jump spikes exceeding maxJumpMeters', () {
      final p1 = LocationPoint(id: '1', latitude: 0.0, longitude: 0.0, timestamp: now);
      // Spike jump (~111 km away)
      final spike = LocationPoint(id: 'spike', latitude: 1.0, longitude: 0.0, timestamp: now.add(const Duration(seconds: 2)));
      // Normal next point (~50 meters away)
      final p2 = LocationPoint(id: '2', latitude: 0.00045, longitude: 0.0, timestamp: now.add(const Duration(seconds: 4)));

      final result = filter.filter([p1, spike, p2]);

      expect(result.where((p) => p.id == 'spike'), isEmpty);
    });
  });
}
