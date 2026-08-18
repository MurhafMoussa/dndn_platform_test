import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../data/services/location_service.dart';
import '../../../domain/failures/tracking_failure.dart';
import '../../../domain/models/incident_report.dart';
import '../../../domain/models/location_point.dart';
import '../../../domain/repositories/tracking_repository.dart';
import 'map_state.dart';

/// Cubit managing location points stream, active tracking service, and map presentation states.
class MapCubit extends Cubit<MapState> {
  final TrackingRepository repository;
  final LocationService locationService;

  StreamSubscription<Either<TrackingFailure, List<LocationPoint>>>? _pointsSubscription;
  StreamSubscription<Either<TrackingFailure, List<IncidentReport>>>? _incidentsSubscription;
  StreamSubscription<Either<TrackingFailure, LocationPoint>>? _locationStreamSubscription;
  bool _isTracking = false;

  MapCubit({
    required this.repository,
    required this.locationService,
  }) : super(const MapInitial());

  /// Initializes the map by observing stored location points and incident reports from the repository.
  Future<void> initializeMap() async {
    emit(const MapLoading());

    if (_pointsSubscription != null) {
      await _pointsSubscription!.cancel();
      _pointsSubscription = null;
    }
    if (_incidentsSubscription != null) {
      await _incidentsSubscription!.cancel();
      _incidentsSubscription = null;
    }

    _incidentsSubscription = repository.watchIncidents().listen(
      (either) {
        either.fold(
          (_) {},
          (incidentsList) {
            if (state is MapLoaded) {
              final currentState = state as MapLoaded;
              emit(currentState.copyWith(incidents: incidentsList));
            }
          },
        );
      },
    );

    _pointsSubscription = repository.watchLocationPoints().listen(
      (either) {
        either.fold(
          (failure) => emit(MapFailure(failure)),
          (points) {
            final currentLoc = points.isNotEmpty ? points.last : null;
            final existingIncidents = state is MapLoaded ? (state as MapLoaded).incidents : <IncidentReport>[];

            emit(
              MapLoaded(
                locationPoints: points,
                incidents: existingIncidents,
                currentLocation: currentLoc,
                isTracking: _isTracking,
              ),
            );
          },
        );
      },
      onError: (Object error) {
        emit(
          MapFailure(
            DatabaseFailure(
              'Error observing location points: ${error.toString()}',
              error,
            ),
          ),
        );
      },
    );
  }

  /// Starts periodic GPS location tracking and records points to repository.
  Future<void> startTracking() async {
    _isTracking = true;
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(isTracking: true));
    }

    await _locationStreamSubscription?.cancel();
    _locationStreamSubscription = locationService.getLocationStream().listen(
      (either) async {
        await either.fold(
          (failure) async {
            _isTracking = false;
            emit(MapFailure(failure));
          },
          (point) async {
            await repository.addLocationPoint(point);
            if (state is MapLoaded) {
              final currentState = state as MapLoaded;
              emit(
                currentState.copyWith(
                  currentLocation: point,
                  isTracking: true,
                ),
              );
            }
          },
        );
      },
      onError: (Object error) {
        _isTracking = false;
        emit(
          MapFailure(
            LocationPermissionDeniedFailure(
              message: 'Location tracking stream error: ${error.toString()}',
              cause: error,
            ),
          ),
        );
      },
    );
  }

  /// Stops periodic GPS location tracking.
  Future<void> stopTracking() async {
    _isTracking = false;
    await _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;

    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(isTracking: false));
    }
  }

  /// Opens system location settings to allow user to turn on GPS.
  Future<void> openLocationSettings() async {
    await locationService.openLocationSettings();
  }

  /// Explicitly handles location permission failures.
  void handlePermissionFailure(LocationPermissionDeniedFailure failure) {
    emit(MapFailure(failure));
  }

  @override
  Future<void> close() async {
    final sub1 = _pointsSubscription;
    _pointsSubscription = null;
    if (sub1 != null) {
      await sub1.cancel();
    }

    final subInc = _incidentsSubscription;
    _incidentsSubscription = null;
    if (subInc != null) {
      await subInc.cancel();
    }

    final sub2 = _locationStreamSubscription;
    _locationStreamSubscription = null;
    if (sub2 != null) {
      await sub2.cancel();
    }

    await super.close();
  }
}
