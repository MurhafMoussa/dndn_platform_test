import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/incident_report.dart';
import '../../domain/models/location_point.dart';
import '../../presentation/widgets/home_widget_map_snapshot.dart';

/// Service responsible for formatting telemetry metrics, rendering offscreen route map snapshots,
/// and updating Android and iOS native home screen widgets via [HomeWidget].
class HomeWidgetService {
  static const String smallWidgetProvider = 'SmallTelemetryWidgetProvider';
  static const String largeWidgetProvider = 'LargeTelemetryWidgetProvider';

  static const String keyTotalDistance = 'total_distance_display';
  static const String keyWaypointsCount = 'waypoints_count';
  static const String keyIsTracking = 'is_tracking';
  static const String keyMapSnapshotPath = 'map_snapshot_path';

  /// Formats distance in meters into human-readable string (e.g. `1,250 m` or `3.4 km`).
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  /// Formats waypoints count into a string.
  static String formatWaypoints(int count) {
    return '$count pts';
  }

  /// Updates both small and large home screen widgets with the latest telemetry data and route map snapshot.
  Future<void> updateWidgetData({
    required double distanceMeters,
    required List<LocationPoint> points,
    List<IncidentReport> incidents = const [],
    bool isTracking = true,
  }) async {
    try {
      final distanceText = formatDistance(distanceMeters);
      final pointsText = formatWaypoints(points.length);

      await HomeWidget.saveWidgetData<String>(keyTotalDistance, distanceText);
      await HomeWidget.saveWidgetData<String>(keyWaypointsCount, pointsText);
      await HomeWidget.saveWidgetData<bool>(keyIsTracking, isTracking);

      final snapshotBytes = await HomeWidgetMapSnapshot.generateSnapshotBytes(
        points: points,
        incidents: incidents,
      );

      final tempDir = await getTemporaryDirectory();
      final imageFile = File('${tempDir.path}/home_widget_map.png');
      await imageFile.writeAsBytes(snapshotBytes, flush: true);

      await HomeWidget.saveWidgetData<String>(
        keyMapSnapshotPath,
        imageFile.path,
      );

      await HomeWidget.updateWidget(
        androidName: smallWidgetProvider,
        name: smallWidgetProvider,
      );

      await HomeWidget.updateWidget(
        androidName: largeWidgetProvider,
        name: largeWidgetProvider,
      );
    } catch (_) {
      // Ignore errors if widget updates are unsupported or interrupted
    }
  }
}
