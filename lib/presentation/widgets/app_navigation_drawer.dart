import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 36,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'Location & Telemetry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                BlocBuilder<UserRoleCubit, UserRole>(
                  builder: (context, activeRole) {
                    final roleLabel = activeRole == UserRole.admin ? 'Admin Session' : 'User Session';
                    return Text(
                      roleLabel,
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
              minVerticalPadding: 12,
              leading: const Icon(Icons.map_rounded),
              title: const Text('Map & Tracking'),
              selected: currentRoute == '/' || currentRoute.isEmpty,
              onTap: () {
                Navigator.of(context).pop();
                if (currentRoute != '/') {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ),
          Semantics(
            label: 'Navigate to Admin Telemetry Dashboard',
            button: true,
            child: ListTile(
              minLeadingWidth: 24,
              minVerticalPadding: 12,
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Admin Dashboard'),
              selected: currentRoute == '/admin',
              onTap: () {
                Navigator.of(context).pop();
                if (currentRoute != '/admin') {
                  Navigator.of(context).pushReplacementNamed('/admin');
                }
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'ACCESS CONTROL',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
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
                  subtitle: Text(
                    isAdmin ? 'Admin features unlocked' : 'Standard user mode',
                  ),
                  value: isAdmin,
                  onChanged: (_) {
                    context.read<UserRoleCubit>().toggleRole();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
