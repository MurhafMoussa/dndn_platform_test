import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/location_permission/location_permission_cubit.dart';
import '../cubits/location_permission/location_permission_state.dart';
import 'location_permission_error_view.dart';

/// Application-level wrapper widget ensuring location permissions are granted before rendering children.
class LocationPermissionGuard extends StatelessWidget {
  final Widget child;

  const LocationPermissionGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationPermissionCubit, LocationPermissionState>(
      builder: (context, state) {
        return switch (state) {
          LocationPermissionGranted() => child,
          LocationPermissionDenied(:final failure) => LocationPermissionErrorView(failure: failure),
          LocationPermissionInitial() || LocationPermissionLoading() => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        };
      },
    );
  }
}
