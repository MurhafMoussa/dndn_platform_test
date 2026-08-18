import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Central application constants and default configuration values.
abstract final class AppConstants {
  static const String appTitle = 'Location & Incident Tracking';
  static const String mapTitle = 'Map & Live Tracking';
  static const String adminTitle = 'Admin Telemetry Dashboard';

  /// Default Mapbox Access Token fallback
  static const String defaultMapboxToken = String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: String.fromEnvironment(
      'MAPBOX_ACCESS_TOKEN',
      defaultValue: 'pk.eyJ1IjoibW9ja3VzZXIiLCJhIjoiY2xidGVzdG1vY2sifQ.mocktoken',
    ),
  );

  /// Default fallback camera coordinates (Damascus, Syria)
  static const double defaultLatitude = 33.5138;
  static const double defaultLongitude = 36.2765;
  static const double defaultZoom = 14.0;

  static final CameraOptions defaultCameraOptions = CameraOptions(
    center: Point(
      coordinates: Position(defaultLongitude, defaultLatitude),
    ),
    zoom: defaultZoom,
  );

  /// Minimum accessible touch target dimension (dp)
  static const double minTouchTargetSize = 48.0;

  /// Route paths
  static const String mapRoute = '/';
  static const String adminRoute = '/admin';
}
