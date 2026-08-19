import 'package:equatable/equatable.dart';

import '../../../domain/failures/tracking_failure.dart';

/// Presentation state for overall location permissions and GPS service status.
sealed class LocationPermissionState extends Equatable {
  const LocationPermissionState();

  @override
  List<Object?> get props => [];
}

/// Initial unverified state before initial permission check completes.
final class LocationPermissionInitial extends LocationPermissionState {
  const LocationPermissionInitial();
}

/// Processing state while verifying or requesting permission.
final class LocationPermissionLoading extends LocationPermissionState {
  const LocationPermissionLoading();
}

/// Active state when location permissions are granted and location service is enabled.
final class LocationPermissionGranted extends LocationPermissionState {
  const LocationPermissionGranted();
}

/// Error state when location permissions are denied, permanently denied, or GPS service is disabled.
final class LocationPermissionDenied extends LocationPermissionState {
  final TrackingFailure failure;

  const LocationPermissionDenied(this.failure);

  @override
  List<Object?> get props => [failure];
}
