import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/incidents_table.dart';
import 'tables/location_points_table.dart';
import 'tables/sync_outbox_table.dart';

part 'tracking_database.g.dart';

/// Primary Drift local database coordinating persistent SQLite tables.
@DriftDatabase(tables: [LocationPoints, Incidents, SyncOutbox])
class TrackingDatabase extends _$TrackingDatabase {
  /// Default production constructor creating file-backed SQLite database.
  TrackingDatabase() : super(_openConnection());

  /// Custom executor constructor for in-memory testing.
  TrackingDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // --- Reactive Watchers ---

  /// Watches all location points ordered by timestamp ascending.
  Stream<List<LocationPointData>> watchAllLocationPoints() {
    return (select(locationPoints)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)]))
        .watch();
  }

  /// Watches all incident reports ordered by timestamp descending.
  Stream<List<IncidentData>> watchAllIncidents() {
    return (select(incidents)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Watches pending outbox items ordered by creation time ascending.
  Stream<List<SyncOutboxData>> watchPendingOutbox() {
    return (select(syncOutbox)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
        .watch();
  }

  // --- One-time Queries & Mutations ---

  /// Retrieves all location points ordered chronologically.
  Future<List<LocationPointData>> getAllLocationPoints() {
    return (select(locationPoints)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)]))
        .get();
  }

  /// Inserts a new location point record.
  Future<int> insertLocationPoint(LocationPointsCompanion entry) {
    return into(locationPoints).insert(entry, mode: InsertMode.insertOrReplace);
  }

  /// Retrieves all incidents.
  Future<List<IncidentData>> getAllIncidents() {
    return (select(incidents)
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }

  /// Inserts a new incident report record.
  Future<int> insertIncident(IncidentsCompanion entry) {
    return into(incidents).insert(entry, mode: InsertMode.insertOrReplace);
  }

  /// Retrieves pending outbox items.
  Future<List<SyncOutboxData>> getPendingOutboxItems() {
    return (select(syncOutbox)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
        .get();
  }

  /// Inserts an outbox synchronization payload.
  Future<int> insertOutboxItem(SyncOutboxCompanion entry) {
    return into(syncOutbox).insert(entry, mode: InsertMode.insertOrReplace);
  }

  /// Updates status for an outbox entry.
  Future<int> updateOutboxStatus(String id, String newStatus) {
    return (update(syncOutbox)..where((t) => t.id.equals(id)))
        .write(SyncOutboxCompanion(status: Value(newStatus)));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tracking_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
