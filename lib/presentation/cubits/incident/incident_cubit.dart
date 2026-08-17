import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/failures/tracking_failure.dart';
import '../../../domain/models/incident_report.dart';
import '../../../domain/repositories/tracking_repository.dart';
import 'incident_state.dart';

/// Cubit managing incident form submission workflow and presentation states.
class IncidentCubit extends Cubit<IncidentState> {
  final TrackingRepository repository;
  final Uuid _uuid;

  IncidentCubit({
    required this.repository,
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid(),
        super(const IncidentInitial());

  /// Resets the form state back to [IncidentInitial].
  void reset() {
    emit(const IncidentInitial());
  }

  /// Submits an incident report with [type], [latitude], and [longitude].
  Future<Either<TrackingFailure, Unit>> submitIncident({
    required IncidentType type,
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) async {
    emit(const IncidentSubmitting());

    final report = IncidentReport(
      id: _uuid.v4(),
      type: type,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime.now(),
    );

    final result = await repository.addIncidentReport(report);

    result.fold(
      (failure) {
        emit(IncidentFailure(failure));
      },
      (_) {
        emit(IncidentSuccess(report));
      },
    );

    return result;
  }
}
