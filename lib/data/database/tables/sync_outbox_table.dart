import 'package:drift/drift.dart';

/// Drift table definition for offline outbox synchronization queue items.
@DataClassName('SyncOutboxData')
class SyncOutbox extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Event type identifier (e.g. 'location_point_created', 'incident_reported').
  TextColumn get eventType => text().named('event_type')();

  /// JSON formatted payload string.
  TextColumn get payload => text()();

  /// Unix timestamp in milliseconds when enqueued.
  IntColumn get createdAt => integer().named('created_at')();

  /// Processing status ('pending', 'syncing', 'synced', 'failed').
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}
