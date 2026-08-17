import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Reusable metric card widget for displaying administrative telemetry metrics.
class TelemetryCard extends StatelessWidget {
  /// Icon representing the telemetry metric.
  final IconData icon;

  /// Title describing the metric (e.g., "Total Distance").
  final String title;

  /// Formatted value text (e.g., "1,250 m").
  final String value;

  /// Optional background color tint for the icon badge.
  final Color? iconColor;

  const TelemetryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '$title: $value',
      readOnly: true,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderMd,
        ),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.12),
                  borderRadius: AppRadii.borderMd,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor ?? colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
