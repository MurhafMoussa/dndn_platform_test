import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/user_role.dart';
import '../cubits/user_role_cubit.dart';

/// Reusable navigation drawer with route navigation and active user role toggle.
class AppNavigationDrawer extends StatelessWidget {
  /// Current active route name to highlight active menu selection.
  final String currentRoute;

  const AppNavigationDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 36,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.navHeaderTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                BlocBuilder<UserRoleCubit, UserRole>(
                  builder: (context, activeRole) {
                    final label = activeRole == UserRole.admin ? AppStrings.adminSession : AppStrings.userSession;
                    return Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Navigate to Map View',
            button: true,
            child: ListTile(
              minLeadingWidth: 24,
              minVerticalPadding: AppSpacing.md,
              leading: const Icon(Icons.map_rounded),
              title: const Text(AppStrings.navMapLabel),
              selected: currentRoute == AppConstants.mapRoute || currentRoute.isEmpty,
              onTap: () {
                Navigator.of(context).pop();
                if (currentRoute != AppConstants.mapRoute) {
                  context.go(AppConstants.mapRoute);
                }
              },
            ),
          ),
          Semantics(
            label: 'Navigate to Admin Telemetry Dashboard',
            button: true,
            child: ListTile(
              minLeadingWidth: 24,
              minVerticalPadding: AppSpacing.md,
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text(AppStrings.navAdminLabel),
              selected: currentRoute == AppConstants.adminRoute,
              onTap: () {
                Navigator.of(context).pop();
                if (currentRoute != AppConstants.adminRoute) {
                  context.go(AppConstants.adminRoute);
                }
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Text(
              'ACCESS CONTROL',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          BlocBuilder<UserRoleCubit, UserRole>(
            builder: (context, activeRole) {
              final isAdmin = activeRole == UserRole.admin;
              return Semantics(
                label: 'Toggle administrator role switch',
                toggled: isAdmin,
                child: SwitchListTile(
                  secondary: Icon(
                    isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                  ),
                  title: const Text('Administrator Mode'),
                  subtitle: Text(isAdmin ? 'Admin features unlocked' : 'Standard user mode'),
                  value: isAdmin,
                  onChanged: (_) => context.read<UserRoleCubit>().toggleRole(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
