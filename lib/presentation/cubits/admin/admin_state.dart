import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/failures/tracking_failure.dart';
import '../../../domain/models/incident_report.dart';

/// Base abstract presentation state for [AdminCubit].
abstract class AdminState extends Equatable {
  const AdminState();

  /// Option containing failure if state is [AdminUnauthorized] or [AdminFailure], otherwise [none()].
  Option<TrackingFailure> get failureOption => none();

  @override
  List<Object?> get props => [];
}

/// Initial state before role check or telemetry loading.
class AdminInitial extends AdminState {
  const AdminInitial();
}

/// State while computing telemetry metrics and querying local database.
class AdminLoading extends AdminState {
  const AdminLoading();
}

/// State when telemetry metrics and incident logs are successfully loaded for admin sessions.
class AdminLoaded extends AdminState {
  /// Total distance traveled in meters.
  final double totalDistanceMeters;

  /// Total count of recorded location points.
  final int totalPointsCount;

  /// List of submitted incident reports.
  final List<IncidentReport> incidents;

  const AdminLoaded({
    required this.totalDistanceMeters,
    required this.totalPointsCount,
    required this.incidents,
  });

  /// Helper copyWith for immutable state updates.
  AdminLoaded copyWith({
    double? totalDistanceMeters,
    int? totalPointsCount,
    List<IncidentReport>? incidents,
  }) {
    return AdminLoaded(
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalPointsCount: totalPointsCount ?? this.totalPointsCount,
      incidents: incidents ?? this.incidents,
    );
  }

  /// Formatted total distance in meters string (e.g. "1,250 m").
  String get formattedDistance {
    final rounded = totalDistanceMeters.round();
    final formatted = rounded.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatted m';
  }

  @override
  List<Object?> get props => [
        totalDistanceMeters,
        totalPointsCount,
        incidents,
      ];
}

/// State emitted when non-admin session accesses telemetry metrics.
class AdminUnauthorized extends AdminState {
  final TrackingFailure failure;

  const AdminUnauthorized([
    this.failure = const UnauthorizedAccessFailure(),
  ]);

  @override
  Option<TrackingFailure> get failureOption => some(failure);

  @override
  List<Object?> get props => [failure];
}

/// State emitted when querying database metrics fails.
class AdminFailure extends AdminState {
  final TrackingFailure failure;

  const AdminFailure(this.failure);

  @override
  Option<TrackingFailure> get failureOption => some(failure);

  @override
  List<Object?> get props => [failure];
}
