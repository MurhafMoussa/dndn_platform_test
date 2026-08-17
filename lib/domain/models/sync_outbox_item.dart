import 'package:equatable/equatable.dart';

/// Processing status for outbox synchronization items.
enum SyncStatus {
  /// Payload is queued pending transmission.
  pending,

  /// Payload has been successfully dispatched.
  synced,

  /// Processing or transmission failed.
  failed,

  /// Payload in actively being processed/dispatched.
  syncing,
}

/// Represents a payload enqueued in the local outbox for remote synchronization.
class SyncOutboxItem extends Equatable {
  /// Unique identifier for the outbox item.
  final String id;

  /// Event type identifier (e.g. 'location_point_created', 'incident_reported').
  final String eventType;

  /// JSON formatted string payload.
  final String payload;

  /// Timestamp when the item was created in the outbox.
  final DateTime createdAt;

  /// Current processing status.
  final SyncStatus status;

  const SyncOutboxItem({
    required this.id,
    required this.eventType,
    required this.payload,
    required this.createdAt,
    required this.status,
  });

  @override
  List<Object?> get props => [id, eventType, payload, createdAt, status];
}
