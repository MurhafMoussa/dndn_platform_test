import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/failures/tracking_failure.dart';
import '../../../domain/models/incident_report.dart';
import '../../../domain/models/location_point.dart';

/// Camera focus target coordinates and zoom level for map navigation.
class CameraFocusTarget extends Equatable {
  final double latitude;
  final double longitude;
  final double zoom;

  const CameraFocusTarget({
    required this.latitude,
    required this.longitude,
    this.zoom = 16.0,
  });

  @override
  List<Object?> get props => [latitude, longitude, zoom];
}

/// Base abstract presentation state for [MapCubit].
abstract class MapState extends Equatable {
  const MapState();

  /// Option containing failure if state is [MapFailure], otherwise [none()].
  Option<TrackingFailure> get failureOption => none();

  @override
  List<Object?> get props => [];
}

/// Initial state while initializing map view or location checks.
class MapInitial extends MapState {
  const MapInitial();
}

/// State while reading location point history from repository.
class MapLoading extends MapState {
  const MapLoading();
}

/// State when map is initialized and actively watching location points and polyline history.
class MapLoaded extends MapState {
  /// Chronological list of recorded location points for rendering polylines.
  final List<LocationPoint> locationPoints;

  /// List of submitted incident reports to render as map markers.
  final List<IncidentReport> incidents;

  /// Current live GPS location point if available.
  final LocationPoint? currentLocation;

  /// Optional camera target coordinates to center/fly map view to.
  final CameraFocusTarget? cameraFocusTarget;

  /// Flag indicating whether periodic background location tracking is active.
  final bool isTracking;

  /// Cached camera zoom level for preserving state across screen navigation.
  final double savedZoom;

  const MapLoaded({
    required this.locationPoints,
    this.incidents = const [],
    this.currentLocation,
    this.cameraFocusTarget,
    this.isTracking = true,
    this.savedZoom = 14.0,
  });

  /// Helper copyWith for immutable state updates.
  MapLoaded copyWith({
    List<LocationPoint>? locationPoints,
    List<IncidentReport>? incidents,
    LocationPoint? currentLocation,
    CameraFocusTarget? cameraFocusTarget,
    bool? isTracking,
    double? savedZoom,
  }) {
    return MapLoaded(
      locationPoints: locationPoints ?? this.locationPoints,
      incidents: incidents ?? this.incidents,
      currentLocation: currentLocation ?? this.currentLocation,
      cameraFocusTarget: cameraFocusTarget ?? this.cameraFocusTarget,
      isTracking: isTracking ?? this.isTracking,
      savedZoom: savedZoom ?? this.savedZoom,
    );
  }

  @override
  List<Object?> get props => [
        locationPoints,
        incidents,
        currentLocation,
        cameraFocusTarget,
        isTracking,
        savedZoom,
      ];
}

/// State emitted when location tracking or permission verification fails.
class MapFailure extends MapState {
  /// The underlying domain failure.
  final TrackingFailure failure;

  const MapFailure(this.failure);

  @override
  Option<TrackingFailure> get failureOption => some(failure);

  @override
  List<Object?> get props => [failure];
}
