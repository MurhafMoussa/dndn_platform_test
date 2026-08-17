import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/user_role.dart';
import '../cubits/user_role_cubit.dart';
import '../widgets/app_navigation_drawer.dart';

/// Screen displayed when non-admin users attempt to access the guarded `/admin` route.
class UnauthorizedView extends StatelessWidget {
  const UnauthorizedView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.accessRestricted),
      ),
      drawer: const AppNavigationDrawer(currentRoute: AppConstants.adminRoute),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 40,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppStrings.unauthorizedAccess,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.unauthorizedBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Semantics(
                label: 'Switch to Administrator Mode button',
                button: true,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<UserRoleCubit>().setRole(UserRole.admin);
                  },
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text(AppStrings.switchToAdmin),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  context.go(AppConstants.mapRoute);
                },
                icon: const Icon(Icons.map_rounded),
                label: const Text(AppStrings.returnToMap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
