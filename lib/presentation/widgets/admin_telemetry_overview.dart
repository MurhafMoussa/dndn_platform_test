import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import 'telemetry_card.dart';

/// Container widget rendering telemetry cards in a responsive layout.
class AdminTelemetryOverview extends StatelessWidget {
  final String formattedDistance;
  final int totalPointsCount;

  const AdminTelemetryOverview({
    super.key,
    required this.formattedDistance,
    required this.totalPointsCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: TelemetryCard(
                  icon: Icons.straighten_rounded,
                  title: AppStrings.totalDistance,
                  value: formattedDistance,
                  iconColor: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TelemetryCard(
                  icon: Icons.location_on_rounded,
                  title: AppStrings.totalPoints,
                  value: '$totalPointsCount',
                  iconColor: colorScheme.secondary,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            TelemetryCard(
              icon: Icons.straighten_rounded,
              title: AppStrings.totalDistance,
              value: formattedDistance,
              iconColor: colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            TelemetryCard(
              icon: Icons.location_on_rounded,
              title: AppStrings.totalPoints,
              value: '$totalPointsCount',
              iconColor: colorScheme.secondary,
            ),
          ],
        );
      },
    );
  }
}
