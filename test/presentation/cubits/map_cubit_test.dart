import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:dndn_platform_test/data/services/location_service.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';
import 'package:dndn_platform_test/domain/repositories/tracking_repository.dart';
import 'package:dndn_platform_test/presentation/cubits/map/map_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/map/map_state.dart';

class FakeTrackingRepository implements TrackingRepository {
  final StreamController<Either<TrackingFailure, List<LocationPoint>>> pointsController =
      StreamController<Either<TrackingFailure, List<LocationPoint>>>.broadcast();

  final List<LocationPoint> addedPoints = [];

  @override
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints() {
    return pointsController.stream;
  }

  @override
  Future<Either<TrackingFailure, Unit>> addLocationPoint(LocationPoint point) async {
    addedPoints.add(point);
    pointsController.add(Right(List.from(addedPoints)));
    return const Right(unit);
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
  Future<Either<TrackingFailure, Unit>> addIncidentReport(IncidentReport incident) async {
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

  void dispose() {
    pointsController.close();
  }
}

class FakeLocationService extends LocationService {
  final StreamController<Either<TrackingFailure, LocationPoint>> locationStreamController =
      StreamController<Either<TrackingFailure, LocationPoint>>.broadcast();

  @override
  Stream<Either<TrackingFailure, LocationPoint>> getLocationStream({
    dynamic locationSettings,
  }) {
    return locationStreamController.stream;
  }

  void dispose() {
    locationStreamController.close();
  }
}

void main() {
  late FakeTrackingRepository fakeRepository;
  late FakeLocationService fakeLocationService;
  late MapCubit mapCubit;

  setUp(() {
    fakeRepository = FakeTrackingRepository();
    fakeLocationService = FakeLocationService();
    mapCubit = MapCubit(
      repository: fakeRepository,
      locationService: fakeLocationService,
    );
  });

  tearDown(() async {
    await mapCubit.close();
    fakeRepository.dispose();
    fakeLocationService.dispose();
  });

  group('MapCubit', () {
    final now = DateTime.now();

    test('initial state is MapInitial', () {
      expect(mapCubit.state, equals(const MapInitial()));
      expect(mapCubit.state.failureOption.isNone(), isTrue);
    });

    test('initializeMap emits MapLoading and updates to MapLoaded on stream events', () async {
      final p1 = LocationPoint(
        id: 'p1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      final expectFuture = expectLater(
        mapCubit.stream,
        emitsInOrder([
          isA<MapLoading>(),
          isA<MapLoaded>().having((s) => s.locationPoints, 'locationPoints', equals([p1])),
        ]),
      );

      await mapCubit.initializeMap();
      fakeRepository.pointsController.add(Right([p1]));

      await expectFuture;
    });

    test('initializeMap emits MapFailure when watchLocationPoints yields failure', () async {
      const failure = DatabaseFailure('Failed to watch points');

      final expectFuture = expectLater(
        mapCubit.stream,
        emitsInOrder([
          isA<MapLoading>(),
          isA<MapFailure>().having((s) => s.failure, 'failure', equals(failure)),
        ]),
      );

      await mapCubit.initializeMap();
      fakeRepository.pointsController.add(const Left(failure));

      await expectFuture;
    });

    test('startTracking subscribes to location stream and adds points to repository', () async {
      await mapCubit.initializeMap();
      fakeRepository.pointsController.add(const Right([]));

      final p1 = LocationPoint(
        id: 'p1',
        latitude: 10.0,
        longitude: 20.0,
        timestamp: now,
      );

      await mapCubit.startTracking();

      fakeLocationService.locationStreamController.add(Right(p1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeRepository.addedPoints, contains(p1));
      expect(mapCubit.state, isA<MapLoaded>());

      final loadedState = mapCubit.state as MapLoaded;
      expect(loadedState.isTracking, isTrue);
      expect(loadedState.currentLocation, equals(p1));
    });

    test('startTracking emits MapFailure when location stream yields LocationPermissionDeniedFailure', () async {
      const permFailure = LocationPermissionDeniedFailure(
        message: 'Permission denied by user',
      );

      final expectFuture = expectLater(
        mapCubit.stream,
        emitsInOrder([
          isA<MapFailure>().having(
            (s) => s.failureOption.toNullable(),
            'failureOption',
            equals(permFailure),
          ),
        ]),
      );

      await mapCubit.startTracking();
      fakeLocationService.locationStreamController.add(const Left(permFailure));

      await expectFuture;
    });

    test('stopTracking sets isTracking to false in MapLoaded state', () async {
      await mapCubit.initializeMap();
      fakeRepository.pointsController.add(const Right([]));

      await mapCubit.startTracking();
      expect((mapCubit.state as MapLoaded).isTracking, isTrue);

      await mapCubit.stopTracking();
      expect((mapCubit.state as MapLoaded).isTracking, isFalse);
    });

    test('handlePermissionFailure emits MapFailure state with failureOption', () {
      const permFailure = LocationPermissionDeniedFailure(
        message: 'Denied permanently',
        isPermanentlyDenied: true,
      );

      mapCubit.handlePermissionFailure(permFailure);

      expect(mapCubit.state, isA<MapFailure>());
      final failureState = mapCubit.state as MapFailure;
      expect(failureState.failure, equals(permFailure));
      expect(failureState.failureOption.toNullable(), equals(permFailure));
    });
  });
}
