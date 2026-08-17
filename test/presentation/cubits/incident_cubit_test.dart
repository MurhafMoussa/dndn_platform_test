import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';
import 'package:dndn_platform_test/domain/repositories/tracking_repository.dart';
import 'package:dndn_platform_test/presentation/cubits/incident/incident_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/incident/incident_state.dart';

class FakeTrackingRepository implements TrackingRepository {
  final List<IncidentReport> addedIncidents = [];
  TrackingFailure? failureToReturn;

  @override
  Future<Either<TrackingFailure, Unit>> addIncidentReport(IncidentReport incident) async {
    if (failureToReturn != null) {
      return Left(failureToReturn!);
    }
    addedIncidents.add(incident);
    return const Right(unit);
  }

  @override
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints() {
    return const Stream.empty();
  }

  @override
  Stream<Either<TrackingFailure, List<IncidentReport>>> watchIncidents() {
    return const Stream.empty();
  }

  @override
  Stream<Either<TrackingFailure, List<SyncOutboxItem>>> watchPendingOutbox() {
    return const Stream.empty();
  }

  @override
  Future<Either<TrackingFailure, Unit>> addLocationPoint(LocationPoint point) async {
    return const Right(unit);
  }

  @override
  TaskEither<TrackingFailure, double> getTotalDistanceMeters() {
    return TaskEither.right(0.0);
  }

  @override
  Future<Either<TrackingFailure, Unit>> flushOutbox() async {
    return const Right(unit);
  }
}

void main() {
  late FakeTrackingRepository fakeRepository;
  late IncidentCubit incidentCubit;

  setUp(() {
    fakeRepository = FakeTrackingRepository();
    incidentCubit = IncidentCubit(repository: fakeRepository);
  });

  tearDown(() async {
    await incidentCubit.close();
  });

  group('IncidentCubit', () {
    final now = DateTime.now();

    test('initial state is IncidentInitial', () {
      expect(incidentCubit.state, equals(const IncidentInitial()));
      expect(incidentCubit.state.failureOption.isNone(), isTrue);
    });

    test('reset emits IncidentInitial state', () async {
      fakeRepository.failureToReturn = const DatabaseFailure('Test error');
      await incidentCubit.submitIncident(
        type: IncidentType.police,
        latitude: 10.0,
        longitude: 20.0,
      );

      expect(incidentCubit.state, isA<IncidentFailure>());

      incidentCubit.reset();
      expect(incidentCubit.state, equals(const IncidentInitial()));
    });

    test('submitIncident emits IncidentSubmitting then IncidentSuccess on successful submission', () async {
      final expectFuture = expectLater(
        incidentCubit.stream,
        emitsInOrder([
          isA<IncidentSubmitting>(),
          isA<IncidentSuccess>().having(
            (s) => s.report,
            'report',
            isA<IncidentReport>()
                .having((r) => r.type, 'type', equals(IncidentType.police))
                .having((r) => r.latitude, 'latitude', equals(37.7749))
                .having((r) => r.longitude, 'longitude', equals(-122.4194)),
          ),
        ]),
      );

      final result = await incidentCubit.submitIncident(
        type: IncidentType.police,
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      expect(result.isRight(), isTrue);
      expect(fakeRepository.addedIncidents.length, equals(1));
      expect(fakeRepository.addedIncidents.first.type, equals(IncidentType.police));

      await expectFuture;
    });

    test('submitIncident submits accident and trafficHeavy incident types correctly', () async {
      await incidentCubit.submitIncident(
        type: IncidentType.accident,
        latitude: 0.0,
        longitude: 0.0,
        timestamp: now,
      );

      expect(fakeRepository.addedIncidents.last.type, equals(IncidentType.accident));

      await incidentCubit.submitIncident(
        type: IncidentType.trafficHeavy,
        latitude: 1.0,
        longitude: 1.0,
        timestamp: now,
      );

      expect(fakeRepository.addedIncidents.last.type, equals(IncidentType.trafficHeavy));
    });

    test('submitIncident emits IncidentSubmitting then IncidentFailure on repository error', () async {
      const dbFailure = DatabaseFailure('Failed to write incident to local SQLite DB');
      fakeRepository.failureToReturn = dbFailure;

      final expectFuture = expectLater(
        incidentCubit.stream,
        emitsInOrder([
          isA<IncidentSubmitting>(),
          isA<IncidentFailure>().having(
            (s) => s.failureOption.toNullable(),
            'failureOption',
            equals(dbFailure),
          ),
        ]),
      );

      final result = await incidentCubit.submitIncident(
        type: IncidentType.police,
        latitude: 10.0,
        longitude: 20.0,
      );

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, equals(dbFailure)),
        (_) => fail('Should fail'),
      );

      await expectFuture;
    });
  });
}
