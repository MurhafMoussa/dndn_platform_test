import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/location_service.dart';
import 'location_permission_state.dart';

/// Cubit that manages location permission status and reacts to background-to-foreground app lifecycle changes.
class LocationPermissionCubit extends Cubit<LocationPermissionState> with WidgetsBindingObserver {
  final LocationService locationService;

  LocationPermissionCubit({
    required this.locationService,
  }) : super(const LocationPermissionInitial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Verifies location permission status without prompting user if [requestIfNeeded] is false.
  Future<void> checkPermission({bool requestIfNeeded = false}) async {
    emit(const LocationPermissionLoading());
    final result = requestIfNeeded
        ? await locationService.checkAndRequestPermission()
        : await locationService.checkPermissionStatus();

    result.fold(
      (failure) => emit(LocationPermissionDenied(failure)),
      (_) => emit(const LocationPermissionGranted()),
    );
  }

  /// Explicitly requests location permission from user.
  Future<void> requestPermission() async {
    await checkPermission(requestIfNeeded: true);
  }

  /// Opens native device location settings screen.
  Future<void> openLocationSettings() async {
    await locationService.openLocationSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPermission(requestIfNeeded: false);
    }
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    await super.close();
  }
}
