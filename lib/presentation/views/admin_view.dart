import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/user_role.dart';
import '../cubits/admin/admin_cubit.dart';
import '../cubits/admin/admin_state.dart';
import '../cubits/user_role_cubit.dart';
import '../widgets/admin_telemetry_explanation_card.dart';
import '../widgets/admin_telemetry_overview.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/incidents_table.dart';
import 'unauthorized_view.dart';

/// Telemetry dashboard screen for administrator sessions.
class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  @override
  void initState() {
    super.initState();
    final role = context.read<UserRoleCubit>().state;
    context.read<AdminCubit>().loadTelemetry(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<UserRoleCubit, UserRole>(
      listener: (context, activeRole) {
        context.read<AdminCubit>().loadTelemetry(activeRole);
      },
      builder: (context, activeRole) {
        if (activeRole == UserRole.user) {
          return const UnauthorizedView(showScaffold: true);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.adminTitle),
          ),
          drawer: const AppNavigationDrawer(currentRoute: AppConstants.adminRoute),
          body: BlocBuilder<AdminCubit, AdminState>(
            builder: (context, state) {
              if (state is AdminUnauthorized) {
                return const UnauthorizedView(showScaffold: false);
              }
              if (state is AdminLoading || state is AdminInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is AdminFailure) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                        const SizedBox(height: AppSpacing.lg),
                        Text(AppStrings.telemetryErrorTitle, style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(state.failure.message, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.xl),
                        ElevatedButton.icon(
                          onPressed: () => context.read<AdminCubit>().loadTelemetry(activeRole),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is AdminLoaded) {
                return SingleChildScrollView(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.telemetryOverview,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AdminTelemetryOverview(
                        formattedDistance: state.formattedDistance,
                        totalPointsCount: state.totalPointsCount,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const AdminTelemetryExplanationCard(),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        AppStrings.incidentReportsLog,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Padding(
                          padding: AppSpacing.paddingSm,
                          child: IncidentsTable(
                            incidents: state.incidents,
                            onViewOnMap: (lat, lng) {
                              context.go('/?lat=$lat&lng=$lng');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}
