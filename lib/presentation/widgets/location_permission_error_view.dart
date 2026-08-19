import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/failures/tracking_failure.dart';
import '../cubits/location_permission/location_permission_cubit.dart';

/// Full-screen or overlay view indicating location permissions are denied or disabled.
class LocationPermissionErrorView extends StatelessWidget {
  final TrackingFailure failure;

  const LocationPermissionErrorView({
    super.key,
    required this.failure,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPermanentlyDenied = failure is LocationPermissionDeniedFailure &&
        (failure as LocationPermissionDeniedFailure).isPermanentlyDenied;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  size: 64,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppStrings.locationFailureTitle,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                failure.message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (!isPermanentlyDenied) ...[
                ElevatedButton.icon(
                  onPressed: () => context.read<LocationPermissionCubit>().requestPermission(),
                  icon: const Icon(Icons.security_rounded),
                  label: const Text('Grant Location Permission'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              ElevatedButton.icon(
                onPressed: () => context.read<LocationPermissionCubit>().openLocationSettings(),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Location Settings'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => context.read<LocationPermissionCubit>().checkPermission(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
