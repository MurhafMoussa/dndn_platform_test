import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/failures/tracking_failure.dart';
import '../../../domain/models/incident_report.dart';

/// Base abstract presentation state for [IncidentCubit].
abstract class IncidentState extends Equatable {
  const IncidentState();

  /// Option containing failure if state is [IncidentFailure], otherwise [none()].
  Option<TrackingFailure> get failureOption => none();

  @override
  List<Object?> get props => [];
}

/// Initial form state ready for user interaction.
class IncidentInitial extends IncidentState {
  const IncidentInitial();
}

/// State while incident report submission is in progress.
class IncidentSubmitting extends IncidentState {
  const IncidentSubmitting();
}

/// State when incident report submission succeeds.
class IncidentSuccess extends IncidentState {
  /// The submitted incident report.
  final IncidentReport report;

  const IncidentSuccess(this.report);

  @override
  List<Object?> get props => [report];
}

/// State when incident report submission fails.
class IncidentFailure extends IncidentState {
  /// The underlying failure causing the submission to fail.
  final TrackingFailure failure;

  const IncidentFailure(this.failure);

  @override
  Option<TrackingFailure> get failureOption => some(failure);

  @override
  List<Object?> get props => [failure];
}
