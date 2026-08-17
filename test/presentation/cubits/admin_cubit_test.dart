import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';
import 'package:dndn_platform_test/domain/models/user_role.dart';
import 'package:dndn_platform_test/domain/repositories/tracking_repository.dart';
import 'package:dndn_platform_test/presentation/cubits/admin/admin_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/admin/admin_state.dart';

class FakeTrackingRepository implements TrackingRepository {
  final StreamController<Either<TrackingFailure, List<LocationPoint>>> pointsController =
      StreamController<Either<TrackingFailure, List<LocationPoint>>>.broadcast();

  final StreamController<Either<TrackingFailure, List<IncidentReport>>> incidentsController =
      StreamController<Either<TrackingFailure, List<IncidentReport>>>.broadcast();

  double calculatedDistance = 0.0;
  TrackingFailure? distanceFailure;

  @override
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints() {
    return pointsController.stream;
  }

  @override
  Stream<Either<TrackingFailure, List<IncidentReport>>> watchIncidents() {
    return incidentsController.stream;
  }

  @override
  TaskEither<TrackingFailure, double> getTotalDistanceMeters() {
    if (distanceFailure != null) {
      return TaskEither.left(distanceFailure!);
    }
    return TaskEither.right(calculatedDistance);
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
  Future<Either<TrackingFailure, Unit>> addIncidentReport(IncidentReport incident) async {
    return const Right(unit);
  }

  @override
  Future<Either<TrackingFailure, Unit>> flushOutbox() async {
    return const Right(unit);
  }

  void dispose() {
    pointsController.close();
    incidentsController.close();
  }
}

void main() {
  late FakeTrackingRepository fakeRepository;
  late AdminCubit adminCubit;

  setUp(() {
    fakeRepository = FakeTrackingRepository();
    adminCubit = AdminCubit(repository: fakeRepository);
  });

  tearDown(() async {
    await adminCubit.close();
    fakeRepository.dispose();
  });

  group('AdminCubit', () {
    final now = DateTime.now();

    test('initial state is AdminInitial', () {
      expect(adminCubit.state, equals(const AdminInitial()));
      expect(adminCubit.state.failureOption.isNone(), isTrue);
    });

    test('loadTelemetry for UserRole.user emits AdminUnauthorized', () async {
      await adminCubit.loadTelemetry(UserRole.user);

      expect(adminCubit.state, isA<AdminUnauthorized>());
      expect(
        adminCubit.state.failureOption.toNullable(),
        isA<UnauthorizedAccessFailure>(),
      );
    });

    test('loadTelemetry for UserRole.admin emits AdminLoading then AdminLoaded on stream data', () async {
      fakeRepository.calculatedDistance = 1250.0;
      final p1 = LocationPoint(id: 'p1', latitude: 0, longitude: 0, timestamp: now);
      final p2 = LocationPoint(id: 'p2', latitude: 0, longitude: 1, timestamp: now);

      final inc1 = IncidentReport(
        id: 'inc1',
        type: IncidentType.police,
        latitude: 0,
        longitude: 0,
        timestamp: now,
      );

      final expectFuture = expectLater(
        adminCubit.stream,
        emitsInOrder([
          isA<AdminLoading>(),
          isA<AdminLoaded>(),
        ]),
      );

      await adminCubit.loadTelemetry(UserRole.admin);
      fakeRepository.pointsController.add(Right([p1, p2]));
      fakeRepository.incidentsController.add(Right([inc1]));

      await expectFuture;

      expect(adminCubit.state, isA<AdminLoaded>());
      final loadedState = adminCubit.state as AdminLoaded;
      expect(loadedState.totalDistanceMeters, equals(1250.0));
      expect(loadedState.formattedDistance, equals('1,250 m'));
      expect(loadedState.totalPointsCount, equals(2));
      expect(loadedState.incidents.length, equals(1));
    });

    test('formattedDistance formats distances correctly', () {
      const stateZero = AdminLoaded(
        totalDistanceMeters: 0.0,
        totalPointsCount: 0,
        incidents: [],
      );
      expect(stateZero.formattedDistance, equals('0 m'));

      const stateThousand = AdminLoaded(
        totalDistanceMeters: 1250000.0,
        totalPointsCount: 100,
        incidents: [],
      );
      expect(stateThousand.formattedDistance, equals('1,250,000 m'));
    });

    test('loadTelemetry emits AdminFailure when points stream yields error', () async {
      const dbFailure = DatabaseFailure('Failed to query points table');

      final expectFuture = expectLater(
        adminCubit.stream,
        emitsInOrder([
          isA<AdminLoading>(),
          isA<AdminFailure>().having(
            (s) => s.failureOption.toNullable(),
            'failureOption',
            equals(dbFailure),
          ),
        ]),
      );

      await adminCubit.loadTelemetry(UserRole.admin);
      fakeRepository.pointsController.add(const Left(dbFailure));

      await expectFuture;
    });

    test('switching from UserRole.admin to UserRole.user emits AdminUnauthorized', () async {
      fakeRepository.calculatedDistance = 100.0;
      await adminCubit.loadTelemetry(UserRole.admin);
      fakeRepository.pointsController.add(const Right([]));
      fakeRepository.incidentsController.add(const Right([]));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(adminCubit.state, isA<AdminLoaded>());

      await adminCubit.loadTelemetry(UserRole.user);
      expect(adminCubit.state, isA<AdminUnauthorized>());
    });
  });
}
