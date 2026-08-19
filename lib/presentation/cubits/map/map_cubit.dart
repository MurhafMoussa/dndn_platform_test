import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../data/services/home_widget_service.dart';
import '../../../data/services/location_service.dart';
import '../../../domain/failures/tracking_failure.dart';
import '../../../domain/models/incident_report.dart';
import '../../../domain/models/location_point.dart';
import '../../../domain/repositories/tracking_repository.dart';
import 'map_state.dart';

/// Cubit managing location tracking streams, incidents, camera focus, home widget updates, and map presentation states.
class MapCubit extends Cubit<MapState> {
  final TrackingRepository repository;
  final LocationService locationService;
  final HomeWidgetService homeWidgetService;

  StreamSubscription<Either<TrackingFailure, List<LocationPoint>>>? _pointsSubscription;
  StreamSubscription<Either<TrackingFailure, List<IncidentReport>>>? _incidentsSubscription;
  StreamSubscription<Either<TrackingFailure, LocationPoint>>? _locationStreamSubscription;

  MapCubit({
    required this.repository,
    required this.locationService,
    HomeWidgetService? homeWidgetService,
  })  : homeWidgetService = homeWidgetService ?? HomeWidgetService(),
        super(const MapInitial());

  /// Initializes the map screen by setting up streams and starting location tracking.
  Future<void> initializeMap() async {
    emit(const MapLoading());
    await _cancelSubscriptions();
    _subscribeToIncidents();
    _subscribeToLocationPoints();
    await startTracking();
    await _acquireInitialLocation();
  }

  /// Starts periodic GPS tracking and sets [isTracking] to true.
  Future<void> startTracking() async {
    await _locationStreamSubscription?.cancel();
    _subscribeToLiveLocationStream();
    _updateTrackingState(isTracking: true);
  }

  /// Stops active GPS location stream and sets [isTracking] to false.
  Future<void> stopTracking() async {
    await _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
    _updateTrackingState(isTracking: false);
  }

  /// Toggles periodic GPS tracking between active and paused.
  Future<void> toggleTracking() async {
    if (state is MapLoaded && (state as MapLoaded).isTracking) {
      await stopTracking();
    } else {
      await startTracking();
    }
  }

  /// Saves current map camera zoom level to state for preservation across screen navigation.
  void saveZoomLevel(double zoom) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      if (currentState.savedZoom != zoom) {
        emit(currentState.copyWith(savedZoom: zoom));
      }
    }
  }

  /// Sets camera target focus coordinates for map navigation.
  void focusLocation(double latitude, double longitude, {double zoom = 16.0}) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(
        currentState.copyWith(
          cameraFocusTarget: CameraFocusTarget(
            latitude: latitude,
            longitude: longitude,
            zoom: zoom,
          ),
          savedZoom: zoom,
        ),
      );
    }
  }

  /// Resets camera target back to user live location.
  Future<void> recenterToUserLocation() async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      if (currentState.currentLocation != null) {
        focusLocation(
          currentState.currentLocation!.latitude,
          currentState.currentLocation!.longitude,
          zoom: currentState.savedZoom,
        );
      }
    }

    final locationResult = await locationService.getLastKnownLocation();
    locationResult.fold(
      (failure) {
        if (state is MapLoaded) {
          final currentState = state as MapLoaded;
          if (currentState.currentLocation != null) {
            focusLocation(
              currentState.currentLocation!.latitude,
              currentState.currentLocation!.longitude,
              zoom: currentState.savedZoom,
            );
          } else {
            emit(MapFailure(failure));
          }
        }
      },
      (point) {
        final savedZoom = state is MapLoaded ? (state as MapLoaded).savedZoom : 16.0;
        _onLiveLocationPointReceived(point);
        focusLocation(point.latitude, point.longitude, zoom: savedZoom);
      },
    );
  }

  /// Opens system location settings dialog.
  Future<void> openLocationSettings() async {
    await locationService.openLocationSettings();
  }

  /// Handles explicit location permission failure.
  void handlePermissionFailure(LocationPermissionDeniedFailure failure) {
    emit(MapFailure(failure));
  }

  // --- Private Single Responsibility Helper Methods ---

  void _subscribeToIncidents() {
    _incidentsSubscription = repository.watchIncidents().listen(
      (either) => either.fold((_) {}, _onIncidentListReceived),
    );
  }

  void _subscribeToLocationPoints() {
    _pointsSubscription = repository.watchLocationPoints().listen(
      (either) => either.fold(
        (failure) => emit(MapFailure(failure)),
        (points) async {
          _onLocationPointsReceived(points);
          await _refreshHomeWidget(points);
        },
      ),
      onError: (Object error) => emit(
        MapFailure(DatabaseFailure('Error observing location points: ${error.toString()}', error)),
      ),
    );
  }

  void _subscribeToLiveLocationStream() {
    _locationStreamSubscription = locationService.getLocationStream().listen(
      (either) async {
        await either.fold(
          (failure) async => emit(MapFailure(failure)),
          (point) async {
            await repository.addLocationPoint(point);
            _onLiveLocationPointReceived(point);
          },
        );
      },
      onError: (Object error) => emit(
        MapFailure(
          LocationPermissionDeniedFailure(
            message: 'Location tracking stream error: ${error.toString()}',
            cause: error,
          ),
        ),
      ),
    );
  }

  Future<void> _acquireInitialLocation() async {
    final locationResult = await locationService.getLastKnownLocation();
    locationResult.fold(
      (_) {},
      (point) {
        _onLiveLocationPointReceived(point);
        final currentZoom = state is MapLoaded ? (state as MapLoaded).savedZoom : 16.0;
        focusLocation(point.latitude, point.longitude, zoom: currentZoom);
      },
    );
  }

  void _onIncidentListReceived(List<IncidentReport> incidents) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(incidents: incidents));
    }
  }

  void _onLocationPointsReceived(List<LocationPoint> points) {
    final currentLoc = points.isNotEmpty ? points.last : (state is MapLoaded ? (state as MapLoaded).currentLocation : null);
    final existingIncidents = state is MapLoaded ? (state as MapLoaded).incidents : <IncidentReport>[];
    final existingCameraFocus = state is MapLoaded ? (state as MapLoaded).cameraFocusTarget : null;
    final currentlyTracking = state is MapLoaded ? (state as MapLoaded).isTracking : true;
    final savedZoom = state is MapLoaded ? (state as MapLoaded).savedZoom : 14.0;

    emit(
      MapLoaded(
        locationPoints: points,
        incidents: existingIncidents,
        currentLocation: currentLoc,
        cameraFocusTarget: existingCameraFocus,
        isTracking: currentlyTracking,
        savedZoom: savedZoom,
      ),
    );
  }

  Future<void> _refreshHomeWidget(List<LocationPoint> points) async {
    try {
      final distanceResult = await repository.getTotalDistanceMeters().run();
      final distance = distanceResult.getOrElse((_) => 0.0);
      final existingIncidents = state is MapLoaded ? (state as MapLoaded).incidents : <IncidentReport>[];
      final isTracking = state is MapLoaded ? (state as MapLoaded).isTracking : true;
      await homeWidgetService.updateWidgetData(
        distanceMeters: distance,
        points: points,
        incidents: existingIncidents,
        isTracking: isTracking,
      );
    } catch (_) {}
  }

  void _onLiveLocationPointReceived(LocationPoint point) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      final target = currentState.cameraFocusTarget ??
          CameraFocusTarget(
            latitude: point.latitude,
            longitude: point.longitude,
            zoom: currentState.savedZoom,
          );
      emit(currentState.copyWith(currentLocation: point, cameraFocusTarget: target));
    } else {
      emit(
        MapLoaded(
          locationPoints: const [],
          currentLocation: point,
          cameraFocusTarget: CameraFocusTarget(
            latitude: point.latitude,
            longitude: point.longitude,
          ),
        ),
      );
    }
  }

  void _updateTrackingState({required bool isTracking}) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(isTracking: isTracking));
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _pointsSubscription?.cancel();
    _pointsSubscription = null;
    await _incidentsSubscription?.cancel();
    _incidentsSubscription = null;
    await _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    await super.close();
  }
}
