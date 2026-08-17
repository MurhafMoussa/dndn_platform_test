import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dndn_platform_test/data/database/tracking_database.dart';

void main() {
  late TrackingDatabase db;

  setUp(() {
    db = TrackingDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TrackingDatabase', () {
    test('schemaVersion is 1', () {
      expect(db.schemaVersion, equals(1));
    });

    test('LocationPoints insert, query, and reactive watcher stream', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = LocationPointsCompanion.insert(
        id: 'p1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      final insertResult = await db.insertLocationPoint(entry);
      expect(insertResult, greaterThan(0));

      final allPoints = await db.getAllLocationPoints();
      expect(allPoints.length, equals(1));
      expect(allPoints.first.id, equals('p1'));
      expect(allPoints.first.latitude, equals(37.7749));

      final streamResult = await db.watchAllLocationPoints().first;
      expect(streamResult.length, equals(1));
      expect(streamResult.first.id, equals('p1'));
    });

    test('Incidents insert, query, and reactive watcher stream', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = IncidentsCompanion.insert(
        id: 'inc1',
        type: 'police',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      final insertResult = await db.insertIncident(entry);
      expect(insertResult, greaterThan(0));

      final allIncidents = await db.getAllIncidents();
      expect(allIncidents.length, equals(1));
      expect(allIncidents.first.id, equals('inc1'));
      expect(allIncidents.first.type, equals('police'));

      final streamResult = await db.watchAllIncidents().first;
      expect(streamResult.length, equals(1));
      expect(streamResult.first.type, equals('police'));
    });

    test('SyncOutbox insert, query pending, update status, and watch pending stream', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = SyncOutboxCompanion.insert(
        id: 'box1',
        eventType: 'location_point_created',
        payload: '{"id": "p1"}',
        createdAt: now,
        status: 'pending',
      );

      final insertResult = await db.insertOutboxItem(entry);
      expect(insertResult, greaterThan(0));

      final pendingItems = await db.getPendingOutboxItems();
      expect(pendingItems.length, equals(1));
      expect(pendingItems.first.id, equals('box1'));
      expect(pendingItems.first.status, equals('pending'));

      final streamBeforeUpdate = await db.watchPendingOutbox().first;
      expect(streamBeforeUpdate.length, equals(1));

      final updateRows = await db.updateOutboxStatus('box1', 'synced');
      expect(updateRows, equals(1));

      final pendingAfterUpdate = await db.getPendingOutboxItems();
      expect(pendingAfterUpdate, isEmpty);

      final streamAfterUpdate = await db.watchPendingOutbox().first;
      expect(streamAfterUpdate, isEmpty);
    });
  });
}
