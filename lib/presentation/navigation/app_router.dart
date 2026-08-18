import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/user_role.dart';
import '../cubits/user_role_cubit.dart';
import '../views/admin_view.dart';
import '../views/map_view.dart';

/// Top-level GoRouter configuration for declarative routing and centralized route guarding.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.mapRoute,
    redirect: (context, state) {
      final isGoingToAdmin = state.matchedLocation == AppConstants.adminRoute;
      try {
        final activeRole = context.read<UserRoleCubit>().state;
        if (isGoingToAdmin && activeRole == UserRole.user) {
          // Centralized route guard: return null allowing AdminView to handle UnauthorizedView
          return null;
        }
      } catch (_) {
        // Fallback when UserRoleCubit is not available in context
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.mapRoute,
        name: 'map',
        builder: (context, state) {
          final latStr = state.uri.queryParameters['lat'];
          final lngStr = state.uri.queryParameters['lng'];
          final lat = latStr != null ? double.tryParse(latStr) : null;
          final lng = lngStr != null ? double.tryParse(lngStr) : null;
          return MapView(targetLat: lat, targetLng: lng);
        },
      ),
      GoRoute(
        path: AppConstants.adminRoute,
        name: 'admin',
        builder: (context, state) => const AdminView(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
    ),
  );
}
