import 'package:flutter_test/flutter_test.dart';
import 'package:dndn_platform_test/data/services/home_widget_service.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/presentation/widgets/home_widget_map_snapshot.dart';

void main() {
  group('HomeWidgetService & Snapshot', () {
    test('formatDistance converts meters to human-readable strings', () {
      expect(HomeWidgetService.formatDistance(0.0), equals('0 m'));
      expect(HomeWidgetService.formatDistance(450.4), equals('450 m'));
      expect(HomeWidgetService.formatDistance(999.0), equals('999 m'));
      expect(HomeWidgetService.formatDistance(1000.0), equals('1.0 km'));
      expect(HomeWidgetService.formatDistance(3450.0), equals('3.5 km'));
      expect(HomeWidgetService.formatDistance(12500.0), equals('12.5 km'));
    });

    test('formatWaypoints formats count into pts label', () {
      expect(HomeWidgetService.formatWaypoints(0), equals('0 pts'));
      expect(HomeWidgetService.formatWaypoints(42), equals('42 pts'));
    });

    test('HomeWidgetMapSnapshot generates non-empty PNG bytes for empty points list', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final bytes = await HomeWidgetMapSnapshot.generateSnapshotBytes(points: []);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('HomeWidgetMapSnapshot generates non-empty PNG bytes for route with multiple points', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final now = DateTime.now();
      final points = [
        LocationPoint(id: '1', latitude: 33.5138, longitude: 36.2765, timestamp: now),
        LocationPoint(id: '2', latitude: 33.5150, longitude: 36.2800, timestamp: now),
        LocationPoint(id: '3', latitude: 33.5200, longitude: 36.2850, timestamp: now),
      ];

      final bytes = await HomeWidgetMapSnapshot.generateSnapshotBytes(points: points);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });
  });
}
