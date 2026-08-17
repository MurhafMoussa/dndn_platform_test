import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';

/// Banner widget indicating active background GPS tracking.
class MapTrackingStatusBanner extends StatelessWidget {
  const MapTrackingStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      top: AppSpacing.lg,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Material(
        elevation: 2,
        borderRadius: AppRadii.borderSm,
        color: colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.my_location_rounded,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppStrings.backgroundTrackingActive,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
