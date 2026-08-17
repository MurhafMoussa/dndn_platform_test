import 'package:equatable/equatable.dart';

/// Base abstract failure class for tracking domain operations.
abstract class TrackingFailure extends Equatable {
  /// User-friendly message describing the failure.
  final String message;

  /// Optional underlying cause or exception.
  final dynamic cause;

  const TrackingFailure(this.message, [this.cause]);

  @override
  List<Object?> get props => [message, cause];
}

/// Thrown when foreground or background location permission is denied by the user.
class LocationPermissionDeniedFailure extends TrackingFailure {
  /// Indicates if permission is permanently denied by OS settings.
  final bool isPermanentlyDenied;

  const LocationPermissionDeniedFailure({
    required String message,
    this.isPermanentlyDenied = false,
    dynamic cause,
  }) : super(message, cause);

  @override
  List<Object?> get props => [message, isPermanentlyDenied, cause];
}

/// Thrown when GPS location services are disabled on the user's device.
class LocationServiceDisabledFailure extends TrackingFailure {
  const LocationServiceDisabledFailure([
    super.message = 'GPS location services are disabled on device.',
    super.cause,
  ]);
}

/// Thrown when a Drift / SQLite read, write, or transaction fails.
class DatabaseFailure extends TrackingFailure {
  const DatabaseFailure(super.message, [super.cause]);
}

/// Thrown when sync outbox payload processing fails.
class SyncFailure extends TrackingFailure {
  const SyncFailure(super.message, [super.cause]);
}

/// Thrown when a non-admin session attempts to access restricted telemetry data.
class UnauthorizedAccessFailure extends TrackingFailure {
  const UnauthorizedAccessFailure([
    super.message = 'Access restricted to administrator sessions only.',
    super.cause,
  ]);
}

/// Thrown when distance calculation fails due to insufficient or invalid coordinates.
class DistanceCalculationFailure extends TrackingFailure {
  const DistanceCalculationFailure(super.message, [super.cause]);
}
