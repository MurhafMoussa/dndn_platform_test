import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';

/// Card widget displaying GPS waypoints telemetry, hazard counts, and info popup button.
class MapStatusCard extends StatelessWidget {
  final int pointsCount;
  final int incidentsCount;
  final double? currentLat;
  final double? currentLng;

  const MapStatusCard({
    super.key,
    required this.pointsCount,
    required this.incidentsCount,
    this.currentLat,
    this.currentLng,
  });

  void _showBreadcrumbsExplanation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(AppStrings.gpsBreadcrumbsExplanationTitle),
          ],
        ),
        content: const Text(AppStrings.gpsBreadcrumbsExplanationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      color: colorScheme.surface.withValues(alpha: 0.92),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppStrings.gpsBreadcrumbsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.primary),
                  tooltip: AppStrings.gpsBreadcrumbsExplanationTitle,
                  onPressed: () => _showBreadcrumbsExplanation(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${AppStrings.waypointsLabel}: $pointsCount | Hazards: $incidentsCount',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
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
    );
  }
}
