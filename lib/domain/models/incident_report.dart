import 'package:equatable/equatable.dart';

/// Types of incidents available for submission.
enum IncidentType {
  /// Police presence / speed trap.
  police,

  /// Road accident or collision.
  accident,

  /// Heavy traffic congestion.
  trafficHeavy,
}

/// Represents a submitted incident report.
class IncidentReport extends Equatable {
  /// Unique identifier for the incident report.
  final String id;

  /// Type of incident reported.
  final IncidentType type;

  /// Latitude coordinate where incident occurred.
  final double latitude;

  /// Longitude coordinate where incident occurred.
  final double longitude;

  /// Timestamp when the incident was reported.
  final DateTime timestamp;

  const IncidentReport({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, type, latitude, longitude, timestamp];
}
