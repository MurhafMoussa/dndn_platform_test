import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dndn_platform_test/data/database/tracking_database.dart';
import 'package:dndn_platform_test/data/sync/sync_engine.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';

void main() {
  late TrackingDatabase db;

  setUp(() {
    db = TrackingDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncEngine', () {
    test('flushPendingOutbox returns Right(0) when outbox is empty', () async {
      final syncEngine = SyncEngine(database: db);
      final result = await syncEngine.flushPendingOutbox();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Should succeed'),
        (count) => expect(count, equals(0)),
      );
    });

    test('flushPendingOutbox processes items and transitions status to synced', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insertOutboxItem(
        SyncOutboxCompanion.insert(
          id: 'box1',
          eventType: 'location_point_created',
          payload: '{"id": "p1", "latitude": 10.0, "longitude": 20.0}',
          createdAt: now,
          status: 'pending',
        ),
      );

      final dispatched = <Map<String, String>>[];
      final syncEngine = SyncEngine(
        database: db,
        customDispatcher: (eventType, payload) async {
          dispatched.add({'eventType': eventType, 'payload': payload});
        },
      );

      final result = await syncEngine.flushPendingOutbox();
      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Should succeed'),
        (count) => expect(count, equals(1)),
      );

      expect(dispatched.length, equals(1));
      expect(dispatched.first['eventType'], equals('location_point_created'));
      expect(dispatched.first['payload'], contains('"id": "p1"'));

      // Verify database status updated to 'synced'
      final pendingAfterSync = await db.getPendingOutboxItems();
      expect(pendingAfterSync, isEmpty);
    });

    test('flushPendingOutbox transitions status to failed on dispatch error and preserves local data', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insertOutboxItem(
        SyncOutboxCompanion.insert(
          id: 'box2',
          eventType: 'incident_reported',
          payload: '{"id": "inc1", "type": "police"}',
          createdAt: now,
          status: 'pending',
        ),
      );

      final syncEngine = SyncEngine(
        database: db,
        customDispatcher: (eventType, payload) async {
          throw Exception('Network dispatch connection timeout');
        },
      );

      final result = await syncEngine.flushPendingOutbox();
      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<SyncFailure>());
          expect(failure.message, contains('Network dispatch connection timeout'));
        },
        (_) => fail('Should fail'),
      );

      // Verify item remains in database with status 'failed'
      final allOutbox = await (db.select(db.syncOutbox)).get();
      expect(allOutbox.length, equals(1));
      expect(allOutbox.first.id, equals('box2'));
      expect(allOutbox.first.status, equals('failed'));
    });
  });
}
