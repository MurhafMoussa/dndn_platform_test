import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/failures/tracking_failure.dart';
import '../../../domain/models/location_point.dart';

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

  /// Current live GPS location point if available.
  final LocationPoint? currentLocation;

  /// Flag indicating whether periodic background location tracking is active.
  final bool isTracking;

  const MapLoaded({
    required this.locationPoints,
    this.currentLocation,
    this.isTracking = false,
  });

  /// Helper copyWith for immutable state updates.
  MapLoaded copyWith({
    List<LocationPoint>? locationPoints,
    LocationPoint? currentLocation,
    bool? isTracking,
  }) {
    return MapLoaded(
      locationPoints: locationPoints ?? this.locationPoints,
      currentLocation: currentLocation ?? this.currentLocation,
      isTracking: isTracking ?? this.isTracking,
    );
  }

  @override
  List<Object?> get props => [locationPoints, currentLocation, isTracking];
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
