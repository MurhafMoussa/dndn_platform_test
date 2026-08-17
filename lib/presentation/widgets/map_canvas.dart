import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';

/// Interactive Mapbox canvas widget displaying route points and status card.
class MapCanvas extends StatelessWidget {
  final MapboxMap? mapboxMap;
  final ValueChanged<MapboxMap> onMapCreated;
  final int pointsCount;
  final double? currentLat;
  final double? currentLng;

  const MapCanvas({
    super.key,
    this.mapboxMap,
    required this.onMapCreated,
    required this.pointsCount,
    this.currentLat,
    this.currentLng,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('mapbox_map_widget'),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          // ignore: deprecated_member_use
          cameraOptions: CameraOptions(
            center: Point(
              coordinates: Position(
                currentLng ?? AppConstants.defaultLongitude,
                currentLat ?? AppConstants.defaultLatitude,
              ),
            ),
            zoom: AppConstants.defaultZoom,
          ),
          onMapCreated: onMapCreated,
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
                      Icon(Icons.map_rounded, size: 20, color: colorScheme.primary),
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
                    'Recorded Points: $pointsCount | Polyline Route Segments: ${pointsCount > 1 ? pointsCount - 1 : 0}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (currentLat != null && currentLng != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Live Location: ${currentLat!.toStringAsFixed(4)}, ${currentLng!.toStringAsFixed(4)}',
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
