import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Central application constants and default configuration values.
abstract final class AppConstants {
  static const String appTitle = 'Dndn Telemetry';
  static const String mapTitle = 'Map & Live Tracking';
  static const String adminTitle = 'Admin Telemetry Dashboard';

  /// Mapbox Access Token passed via environment variables (--dart-define=MAPBOX_ACCESS_TOKEN=...)
  static const String defaultMapboxToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: String.fromEnvironment('ACCESS_TOKEN'),
  );

  /// Default fallback camera coordinates (Configurable via --dart-define=DEFAULT_LATITUDE=... and --dart-define=DEFAULT_LONGITUDE=...)
  static final double defaultLatitude = double.tryParse(
    const String.fromEnvironment('DEFAULT_LATITUDE'),
  ) ?? 33.5138;

  static final double defaultLongitude = double.tryParse(
    const String.fromEnvironment('DEFAULT_LONGITUDE'),
  ) ?? 36.2765;
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
