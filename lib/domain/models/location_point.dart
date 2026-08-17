import 'package:equatable/equatable.dart';

/// Represents a captured GPS coordinate point in time.
class LocationPoint extends Equatable {
  /// Unique identifier for the location point.
  final String id;

  /// Latitude coordinate value.
  final double latitude;

  /// Longitude coordinate value.
  final double longitude;

  /// Timestamp when the point was captured.
  final DateTime timestamp;

  const LocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, latitude, longitude, timestamp];
}
