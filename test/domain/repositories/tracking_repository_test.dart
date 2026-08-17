import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';
import 'package:dndn_platform_test/domain/repositories/tracking_repository.dart';

class FakeTrackingRepository implements TrackingRepository {
  final List<LocationPoint> _points = [];
  final List<IncidentReport> _incidents = [];
  final List<SyncOutboxItem> _outbox = [];

  @override
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints() async* {
    yield Right(_points);
  }

  @override
  Stream<Either<TrackingFailure, List<IncidentReport>>> watchIncidents() async* {
    yield Right(_incidents);
  }

  @override
  Stream<Either<TrackingFailure, List<SyncOutboxItem>>> watchPendingOutbox() async* {
    yield Right(_outbox);
  }

  @override
  Future<Either<TrackingFailure, Unit>> addLocationPoint(LocationPoint point) async {
    _points.add(point);
    return const Right(unit);
  }

  @override
  Future<Either<TrackingFailure, Unit>> addIncidentReport(IncidentReport incident) async {
    _incidents.add(incident);
    return const Right(unit);
  }

  @override
  TaskEither<TrackingFailure, double> getTotalDistanceMeters() {
    return TaskEither.of(1250.0);
  }

  @override
  Future<Either<TrackingFailure, Unit>> flushOutbox() async {
    _outbox.clear();
    return const Right(unit);
  }
}

void main() {
  group('TrackingRepository Interface Contract', () {
    late TrackingRepository repository;

    setUp(() {
      repository = FakeTrackingRepository();
    });

    test('addLocationPoint and watchLocationPoints signature consistency', () async {
      final now = DateTime.now();
      final point = LocationPoint(
        id: 'p1',
        latitude: 10.0,
        longitude: 20.0,
        timestamp: now,
      );

      final addResult = await repository.addLocationPoint(point);
      expect(addResult.isRight(), isTrue);

      final streamResult = await repository.watchLocationPoints().first;
      expect(streamResult.isRight(), isTrue);
      streamResult.match(
        (failure) => fail('Should not fail'),
        (points) {
          expect(points.length, equals(1));
          expect(points.first, equals(point));
        },
      );
    });

    test('addIncidentReport and watchIncidents signature consistency', () async {
      final now = DateTime.now();
      final incident = IncidentReport(
        id: 'inc1',
        type: IncidentType.police,
        latitude: 10.0,
        longitude: 20.0,
        timestamp: now,
      );

      final addResult = await repository.addIncidentReport(incident);
      expect(addResult.isRight(), isTrue);

      final streamResult = await repository.watchIncidents().first;
      expect(streamResult.isRight(), isTrue);
      streamResult.match(
        (failure) => fail('Should not fail'),
        (incidents) {
          expect(incidents.length, equals(1));
          expect(incidents.first, equals(incident));
        },
      );
    });

    test('getTotalDistanceMeters returns TaskEither double', () async {
      final task = repository.getTotalDistanceMeters();
      final result = await task.run();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Should not fail'),
        (distance) => expect(distance, equals(1250.0)),
      );
    });

    test('flushOutbox and watchPendingOutbox signature consistency', () async {
      final flushResult = await repository.flushOutbox();
      expect(flushResult.isRight(), isTrue);

      final outboxResult = await repository.watchPendingOutbox().first;
      expect(outboxResult.isRight(), isTrue);
    });
  });
}
