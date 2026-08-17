import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dndn_platform_test/data/database/tracking_database.dart';
import 'package:dndn_platform_test/data/repositories/tracking_repository_impl.dart';
import 'package:dndn_platform_test/data/sync/sync_engine.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/repositories/tracking_repository.dart';

class FailingDatabase extends TrackingDatabase {
  FailingDatabase() : super.forTesting(NativeDatabase.memory());

  @override
  Future<T> transaction<T>(Future<T> Function() action, {bool? requireNew}) {
    throw Exception('Database transaction failed');
  }
}

void main() {
  late TrackingDatabase db;
  late SyncEngine syncEngine;
  late TrackingRepository repository;
  late List<Map<String, String>> dispatchedPayloads;

  setUp(() {
    db = TrackingDatabase.forTesting(NativeDatabase.memory());
    dispatchedPayloads = [];
    syncEngine = SyncEngine(
      database: db,
      customDispatcher: (eventType, payload) async {
        dispatchedPayloads.add({'eventType': eventType, 'payload': payload});
      },
    );
    repository = TrackingRepositoryImpl(database: db, syncEngine: syncEngine);
  });

  tearDown(() async {
    await db.close();
  });

  group('TrackingRepositoryImpl', () {
    test('addLocationPoint performs atomic write and outbox enqueueing', () async {
      final now = DateTime.now();
      final point = LocationPoint(
        id: 'p1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      final result = await repository.addLocationPoint(point);
      expect(result.isRight(), isTrue);

      // Verify point persisted in DB
      final dbPoints = await db.getAllLocationPoints();
      expect(dbPoints.length, equals(1));
      expect(dbPoints.first.id, equals('p1'));

      // Verify stream emissions
      final streamEmit = await repository.watchLocationPoints().first;
      expect(streamEmit.isRight(), isTrue);
      streamEmit.match(
        (failure) => fail('Should succeed'),
        (points) {
          expect(points.length, equals(1));
          expect(points.first.id, equals('p1'));
        },
      );
    });

    test('addIncidentReport performs atomic write and outbox enqueueing', () async {
      final now = DateTime.now();
      final incident = IncidentReport(
        id: 'inc1',
        type: IncidentType.police,
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      final result = await repository.addIncidentReport(incident);
      expect(result.isRight(), isTrue);

      // Verify incident persisted in DB
      final dbIncidents = await db.getAllIncidents();
      expect(dbIncidents.length, equals(1));
      expect(dbIncidents.first.type, equals('police'));

      // Verify stream emissions
      final streamEmit = await repository.watchIncidents().first;
      expect(streamEmit.isRight(), isTrue);
      streamEmit.match(
        (failure) => fail('Should succeed'),
        (incidents) {
          expect(incidents.length, equals(1));
          expect(incidents.first.type, equals(IncidentType.police));
        },
      );
    });

    test('getTotalDistanceMeters calculates distance between coordinate pairs', () async {
      final now = DateTime.now();
      // Distance between (0, 0) and (0, 1) is ~111,319 meters
      final p1 = LocationPoint(id: 'p1', latitude: 0.0, longitude: 0.0, timestamp: now);
      final p2 = LocationPoint(id: 'p2', latitude: 0.0, longitude: 1.0, timestamp: now.add(const Duration(seconds: 2)));

      await repository.addLocationPoint(p1);
      await repository.addLocationPoint(p2);

      final distanceTask = repository.getTotalDistanceMeters();
      final distanceResult = await distanceTask.run();

      expect(distanceResult.isRight(), isTrue);
      distanceResult.match(
        (failure) => fail('Should succeed'),
        (distance) {
          expect(distance, greaterThan(111000));
          expect(distance, lessThan(112000));
        },
      );
    });

    test('flushOutbox invokes syncEngine and clears pending items', () async {
      final now = DateTime.now();
      final point = LocationPoint(
        id: 'p1',
        latitude: 10.0,
        longitude: 20.0,
        timestamp: now,
      );

      await repository.addLocationPoint(point);

      final flushResult = await repository.flushOutbox();
      expect(flushResult.isRight(), isTrue);

      // Verify pending outbox is empty
      final pendingOutbox = await db.getPendingOutboxItems();
      expect(pendingOutbox, isEmpty);
    });

    test('returns Left(DatabaseFailure) when database transaction fails', () async {
      final failingDb = FailingDatabase();
      final failingRepo = TrackingRepositoryImpl(
        database: failingDb,
        syncEngine: syncEngine,
      );

      final point = LocationPoint(
        id: 'p1',
        latitude: 10.0,
        longitude: 20.0,
        timestamp: DateTime.now(),
      );

      final result = await failingRepo.addLocationPoint(point);
      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, contains('Database transaction failed'));
        },
        (_) => fail('Should fail with DatabaseFailure'),
      );

      await failingDb.close();
    });
  });
}
