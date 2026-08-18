import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/location_point.dart';

/// Interactive Mapbox canvas widget displaying route points and status card.
class MapCanvas extends StatefulWidget {
  final MapboxMap? mapboxMap;
  final ValueChanged<MapboxMap> onMapCreated;
  final int pointsCount;
  final double? currentLat;
  final double? currentLng;
  final List<LocationPoint> locationPoints;

  const MapCanvas({
    super.key,
    this.mapboxMap,
    required this.onMapCreated,
    required this.pointsCount,
    this.currentLat,
    this.currentLng,
    this.locationPoints = const [],
  });

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  PolylineAnnotationManager? _polylineManager;

  @override
  void didUpdateWidget(MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapboxMap != null && _polylineManager != null) {
      if (oldWidget.locationPoints != widget.locationPoints) {
        _renderRoutePolyline();
      }
    }
  }

  Future<void> _handleMapCreated(MapboxMap mapboxMap) async {
    widget.onMapCreated(mapboxMap);
    try {
      await mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          puckBearingEnabled: true,
          locationPuck: LocationPuck(
            locationPuck2D: DefaultLocationPuck2D(),
          ),
        ),
      );
      _polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
      await _renderRoutePolyline();
    } catch (_) {
      // Ignore if map component initialization throws in test environments
    }
  }

  Future<void> _renderRoutePolyline() async {
    if (_polylineManager == null || widget.locationPoints.length < 2) return;
    try {
      await _polylineManager!.deleteAll();
      final coordinates = widget.locationPoints
          .map((p) => Position(p.longitude, p.latitude))
          .toList();
      await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: coordinates),
          lineColor: Colors.blue.toARGB32(),
          lineWidth: 4.0,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('mapbox_map_widget'),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          viewport: CameraViewportState(
            zoom: AppConstants.defaultZoom,
            center: Point(
              coordinates: Position(
                widget.currentLng ?? AppConstants.defaultLongitude,
                widget.currentLat ?? AppConstants.defaultLatitude,
              ),
            ),
          ),
          onMapCreated: _handleMapCreated,
        ),
        Positioned(
          bottom: AppSpacing.lg,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
            color: colorScheme.surface.withValues(alpha: 0.9),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        AppStrings.mapCanvasTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Recorded Points: ${widget.pointsCount} | Polyline Route Segments: ${widget.pointsCount > 1 ? widget.pointsCount - 1 : 0}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.currentLat != null && widget.currentLng != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Live Location: ${widget.currentLat!.toStringAsFixed(4)}, ${widget.currentLng!.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
