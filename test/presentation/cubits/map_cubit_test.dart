import 'dart:async';

import 'package:dndn_platform_test/data/services/location_service.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';
import 'package:dndn_platform_test/domain/repositories/tracking_repository.dart';
import 'package:dndn_platform_test/presentation/cubits/map/map_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/map/map_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class FakeTrackingRepository implements TrackingRepository {
  final StreamController<Either<TrackingFailure, List<LocationPoint>>> pointsController =
      StreamController<Either<TrackingFailure, List<LocationPoint>>>.broadcast();

  final List<LocationPoint> addedPoints = [];

  @override
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints() {
    return pointsController.stream;
  }

  @override
  Future<Either<TrackingFailure, Unit>> addLocationPoint(
    LocationPoint point,
  ) async {
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
  Future<Either<TrackingFailure, Unit>> addIncidentReport(
    IncidentReport incident,
  ) async {
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

  LocationPoint? mockCurrentLocation;
  TrackingFailure? mockLocationFailure;

  @override
  Future<Either<TrackingFailure, LocationPoint>> getLastKnownLocation() async {
    return getCurrentLocation();
  }

  @override
  Future<Either<TrackingFailure, LocationPoint>> getCurrentLocation({
    dynamic locationSettings,
  }) async {
    if (mockLocationFailure != null) {
      return Left(mockLocationFailure!);
    }
    if (mockCurrentLocation != null) {
      return Right(mockCurrentLocation!);
    }
    return const Left(
      LocationPermissionDeniedFailure(message: 'No location available'),
    );
  }

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

  group('CameraFocusTarget & MapLoaded', () {
    test('CameraFocusTarget holds properties and equality', () {
      const target1 = CameraFocusTarget(
        latitude: 33.5138,
        longitude: 36.2765,
        zoom: 16.0,
      );
      const target2 = CameraFocusTarget(
        latitude: 33.5138,
        longitude: 36.2765,
        zoom: 16.0,
      );
      const target3 = CameraFocusTarget(latitude: 10.0, longitude: 20.0);

      expect(target1.latitude, equals(33.5138));
      expect(target1.longitude, equals(36.2765));
      expect(target1.zoom, equals(16.0));
      expect(target1, equals(target2));
      expect(target1, isNot(equals(target3)));
    });

    test(
      'MapLoaded holds cameraFocusTarget and copyWith updates correctly',
      () {
        const target = CameraFocusTarget(latitude: 33.5138, longitude: 36.2765);
        const state = MapLoaded(locationPoints: [], cameraFocusTarget: target);

        expect(state.cameraFocusTarget, equals(target));

        const newTarget = CameraFocusTarget(
          latitude: 34.0,
          longitude: 35.0,
          zoom: 14.0,
        );
        final updatedState = state.copyWith(cameraFocusTarget: newTarget);
        expect(updatedState.cameraFocusTarget, equals(newTarget));
      },
    );
  });

  group('MapCubit', () {
    final now = DateTime.now();

    test('initial state is MapInitial', () {
      expect(mapCubit.state, equals(const MapInitial()));
      expect(mapCubit.state.failureOption.isNone(), isTrue);
    });

    test(
      'initializeMap emits MapLoading and updates to MapLoaded on stream events',
      () async {
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
            isA<MapLoaded>().having(
              (s) => s.locationPoints,
              'locationPoints',
              equals([p1]),
            ),
          ]),
        );

        await mapCubit.initializeMap();
        fakeRepository.pointsController.add(Right([p1]));

        await expectFuture;
      },
    );

    test(
      'initializeMap emits MapFailure when watchLocationPoints yields failure',
      () async {
        const failure = DatabaseFailure('Failed to watch points');

        final expectFuture = expectLater(
          mapCubit.stream,
          emitsInOrder([
            isA<MapLoading>(),
            isA<MapFailure>().having(
              (s) => s.failure,
              'failure',
              equals(failure),
            ),
          ]),
        );

        await mapCubit.initializeMap();
        fakeRepository.pointsController.add(const Left(failure));

        await expectFuture;
      },
    );

    test(
      'startTracking subscribes to location stream and adds points to repository continuously',
      () async {
        final initFuture = mapCubit.initializeMap();
        await Future<void>.delayed(Duration.zero);
        fakeRepository.pointsController.add(const Right([]));
        await initFuture;

        final p1 = LocationPoint(
          id: 'p1',
          latitude: 10.0,
          longitude: 20.0,
          timestamp: now,
        );

        fakeLocationService.locationStreamController.add(Right(p1));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(fakeRepository.addedPoints, contains(p1));
        expect(mapCubit.state, isA<MapLoaded>());

        final loadedState = mapCubit.state as MapLoaded;
        expect(loadedState.currentLocation, equals(p1));
        expect(loadedState.isTracking, isTrue);
      },
    );

    test(
      'startTracking emits MapFailure when location stream yields LocationPermissionDeniedFailure',
      () async {
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
        fakeLocationService.locationStreamController.add(
          const Left(permFailure),
        );

        await expectFuture;
      },
    );

    test(
      'saveZoomLevel updates savedZoom in MapLoaded state',
      () async {
        final initFuture = mapCubit.initializeMap();
        await Future<void>.delayed(Duration.zero);
        fakeRepository.pointsController.add(const Right([]));
        await initFuture;

        mapCubit.saveZoomLevel(18.5);

        expect(mapCubit.state, isA<MapLoaded>());
        final loadedState = mapCubit.state as MapLoaded;
        expect(loadedState.savedZoom, equals(18.5));
      },
    );

    test(
      'focusLocation updates cameraFocusTarget in MapLoaded state',
      () async {
        final initFuture = mapCubit.initializeMap();
        await Future<void>.delayed(Duration.zero);
        fakeRepository.pointsController.add(const Right([]));
        await initFuture;

        mapCubit.focusLocation(33.5138, 36.2765, zoom: 16.0);

        expect(mapCubit.state, isA<MapLoaded>());
        final loadedState = mapCubit.state as MapLoaded;
        expect(
          loadedState.cameraFocusTarget,
          equals(
            const CameraFocusTarget(
              latitude: 33.5138,
              longitude: 36.2765,
              zoom: 16.0,
            ),
          ),
        );
      },
    );

    test(
      'recenterToUserLocation updates cameraFocusTarget to user live location',
      () async {
        final userLoc = LocationPoint(
          id: 'user1',
          latitude: 33.5100,
          longitude: 36.2800,
          timestamp: now,
        );
        fakeLocationService.mockCurrentLocation = userLoc;

        final initFuture = mapCubit.initializeMap();
        await Future<void>.delayed(Duration.zero);
        fakeRepository.pointsController.add(const Right([]));
        await initFuture;

        await mapCubit.recenterToUserLocation();

        expect(mapCubit.state, isA<MapLoaded>());
        final loadedState = mapCubit.state as MapLoaded;
        expect(
          loadedState.cameraFocusTarget,
          equals(
            CameraFocusTarget(
              latitude: userLoc.latitude,
              longitude: userLoc.longitude,
              zoom: 14.0,
            ),
          ),
        );
      },
    );

    test(
      'handlePermissionFailure emits MapFailure state with failureOption',
      () {
        const permFailure = LocationPermissionDeniedFailure(
          message: 'Denied permanently',
          isPermanentlyDenied: true,
        );

        mapCubit.handlePermissionFailure(permFailure);

        expect(mapCubit.state, isA<MapFailure>());
        final failureState = mapCubit.state as MapFailure;
        expect(failureState.failure, equals(permFailure));
        expect(failureState.failureOption.toNullable(), equals(permFailure));
      },
    );
  });
}
