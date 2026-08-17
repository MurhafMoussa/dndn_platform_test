import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/failures/tracking_failure.dart';
import '../../../domain/models/incident_report.dart';
import '../../../domain/models/location_point.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/tracking_repository.dart';
import 'admin_state.dart';

/// Cubit managing telemetry metrics computation, incident log streams, and route role guarding.
class AdminCubit extends Cubit<AdminState> {
  final TrackingRepository repository;

  StreamSubscription<Either<TrackingFailure, List<LocationPoint>>>? _pointsSubscription;
  StreamSubscription<Either<TrackingFailure, List<IncidentReport>>>? _incidentsSubscription;

  List<LocationPoint> _cachedPoints = [];
  List<IncidentReport> _cachedIncidents = [];
  double _cachedDistance = 0.0;

  AdminCubit({
    required this.repository,
  }) : super(const AdminInitial());

  /// Loads telemetry metrics if [activeRole] is [UserRole.admin], or emits [AdminUnauthorized] if [UserRole.user].
  Future<void> loadTelemetry(UserRole activeRole) async {
    if (activeRole == UserRole.user) {
      await _cancelSubscriptions();
      emit(const AdminUnauthorized());
      return;
    }

    emit(const AdminLoading());

    await _cancelSubscriptions();

    _pointsSubscription = repository.watchLocationPoints().listen(
      (either) async {
        await either.fold(
          (failure) async => emit(AdminFailure(failure)),
          (points) async {
            _cachedPoints = points;
            final distanceResult = await repository.getTotalDistanceMeters().run();
            _cachedDistance = distanceResult.getOrElse((_) => 0.0);
            _updateLoadedState();
          },
        );
      },
      onError: (Object error) {
        emit(
          AdminFailure(
            DatabaseFailure('Error observing location points: ${error.toString()}', error),
          ),
        );
      },
    );

    _incidentsSubscription = repository.watchIncidents().listen(
      (either) {
        either.fold(
          (failure) => emit(AdminFailure(failure)),
          (incidents) {
            _cachedIncidents = incidents;
            _updateLoadedState();
          },
        );
      },
      onError: (Object error) {
        emit(
          AdminFailure(
            DatabaseFailure('Error observing incident reports: ${error.toString()}', error),
          ),
        );
      },
    );
  }

  void _updateLoadedState() {
    emit(
      AdminLoaded(
        totalDistanceMeters: _cachedDistance,
        totalPointsCount: _cachedPoints.length,
        incidents: List.unmodifiable(_cachedIncidents),
      ),
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _pointsSubscription?.cancel();
    _pointsSubscription = null;
    await _incidentsSubscription?.cancel();
    _incidentsSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
