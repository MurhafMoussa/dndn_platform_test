import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Responsive card widget rendered in the Admin Telemetry Dashboard (/admin)
/// explaining total location points and total distance calculation metrics.
class AdminTelemetryExplanationCard extends StatelessWidget {
  const AdminTelemetryExplanationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.telemetryExplanationsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isTablet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ExplanationTile(
                      icon: Icons.pin_drop_outlined,
                      title: AppStrings.totalPoints,
                      description:
                          'Discrete GPS coordinate fixes captured locally and queued for offline synchronization.',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ExplanationTile(
                      icon: Icons.route_outlined,
                      title: AppStrings.totalDistance,
                      description:
                          'Calculated using geodesic paths along consecutive chronological location waypoints.',
                    ),
                  ),
                ],
              )
            else
              Column(
                children: const [
                  _ExplanationTile(
                    icon: Icons.pin_drop_outlined,
                    title: AppStrings.totalPoints,
                    description:
                        'Discrete GPS coordinate fixes captured locally and queued for offline synchronization.',
                  ),
                  SizedBox(height: 8),
                  _ExplanationTile(
                    icon: Icons.route_outlined,
                    title: AppStrings.totalDistance,
                    description:
                        'Calculated using geodesic paths along consecutive chronological location waypoints.',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ExplanationTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
