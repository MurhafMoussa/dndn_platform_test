import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:dndn_platform_test/data/database/tracking_database.dart';
import 'package:dndn_platform_test/data/repositories/tracking_repository_impl.dart';
import 'package:dndn_platform_test/data/services/location_service.dart';
import 'package:dndn_platform_test/data/sync/sync_engine.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/user_role.dart';
import 'package:dndn_platform_test/presentation/cubits/admin/admin_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/admin/admin_state.dart';
import 'package:dndn_platform_test/presentation/cubits/incident/incident_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/incident/incident_state.dart';
import 'package:dndn_platform_test/presentation/cubits/map/map_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/map/map_state.dart';
import 'package:dndn_platform_test/presentation/cubits/user_role_cubit.dart';

class MockStorage implements Storage {
  final Map<String, dynamic> _storage = {};

  @override
  dynamic read(String key) => _storage[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<void> close() async {}
}

void main() {
  late TrackingDatabase db;
  late SyncEngine syncEngine;
  late TrackingRepositoryImpl repository;
  late LocationService locationService;
  late List<Map<String, String>> dispatchedPayloads;

  late UserRoleCubit userRoleCubit;
  late MapCubit mapCubit;
  late IncidentCubit incidentCubit;
  late AdminCubit adminCubit;

  setUp(() {
    HydratedBloc.storage = MockStorage();
    db = TrackingDatabase.forTesting(NativeDatabase.memory());
    dispatchedPayloads = [];

    syncEngine = SyncEngine(
      database: db,
      customDispatcher: (eventType, payload) async {
        dispatchedPayloads.add({'eventType': eventType, 'payload': payload});
      },
    );

    repository = TrackingRepositoryImpl(
      database: db,
      syncEngine: syncEngine,
    );

    locationService = LocationService();

    userRoleCubit = UserRoleCubit();
    mapCubit = MapCubit(
      repository: repository,
      locationService: locationService,
    );
    incidentCubit = IncidentCubit(
      repository: repository,
    );
    adminCubit = AdminCubit(
      repository: repository,
    );
  });

  tearDown(() async {
    await mapCubit.close();
    await incidentCubit.close();
    await adminCubit.close();
    await userRoleCubit.close();
    await db.close();
  });

  group('Tracking Platform E2E Integration Workflow', () {
    test('complete offline-first tracking, incident reporting, outbox sync, and role access pipeline', () async {
      // Step 1: Initialize Map View & observe empty local database
      await mapCubit.initializeMap();
      await Future<void>.delayed(Duration.zero);

      expect(mapCubit.state, isA<MapLoaded>());
      final initialMapState = mapCubit.state as MapLoaded;
      expect(initialMapState.locationPoints, isEmpty);
      expect(initialMapState.currentLocation, isNull);

      // Step 2: Record periodic GPS location points locally
      final now = DateTime.now();
      final point1 = LocationPoint(
        id: 'p1',
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );
      final point2 = LocationPoint(
        id: 'p2',
        latitude: 37.7833,
        longitude: -122.4167,
        timestamp: now.add(const Duration(seconds: 2)),
      );

      final addP1Result = await repository.addLocationPoint(point1);
      expect(addP1Result.isRight(), isTrue);

      final addP2Result = await repository.addLocationPoint(point2);
      expect(addP2Result.isRight(), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mapCubit.state, isA<MapLoaded>());
      final loadedMapState = mapCubit.state as MapLoaded;
      expect(loadedMapState.locationPoints.length, equals(2));
      expect(loadedMapState.currentLocation?.id, equals('p2'));

      // Step 3: Report hazard incident offline
      final submitResult = await incidentCubit.submitIncident(
        type: IncidentType.police,
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(submitResult.isRight(), isTrue);
      expect(incidentCubit.state, isA<IncidentSuccess>());

      // Allow background outbox flush microtask to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Step 4: Flush sync outbox and verify dispatch payloads & status transitions
      final flushResult = await repository.flushOutbox();
      expect(flushResult.isRight(), isTrue);

      final pendingOutboxAfterSync = await db.getPendingOutboxItems();
      expect(pendingOutboxAfterSync, isEmpty);

      expect(dispatchedPayloads.length, equals(3));
      expect(dispatchedPayloads[0]['eventType'], equals('location_point_created'));
      expect(dispatchedPayloads[1]['eventType'], equals('location_point_created'));
      expect(dispatchedPayloads[2]['eventType'], equals('incident_reported'));

      final incidentPayloadJson = jsonDecode(dispatchedPayloads[2]['payload']!) as Map<String, dynamic>;
      expect(incidentPayloadJson['type'], equals('police'));

      // Step 5: Verify Admin Telemetry Dashboard metrics and route guarding
      userRoleCubit.setRole(UserRole.admin);
      await adminCubit.loadTelemetry(userRoleCubit.state);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(adminCubit.state, isA<AdminLoaded>());
      final adminLoadedState = adminCubit.state as AdminLoaded;
      expect(adminLoadedState.totalPointsCount, equals(2));
      expect(adminLoadedState.incidents.length, equals(1));
      expect(adminLoadedState.incidents.first.type, equals(IncidentType.police));
      expect(adminLoadedState.totalDistanceMeters, greaterThan(900));

      // Step 6: Guard admin route when switching to non-admin role
      userRoleCubit.setRole(UserRole.user);
      await adminCubit.loadTelemetry(userRoleCubit.state);

      expect(adminCubit.state, isA<AdminUnauthorized>());
      expect(
        adminCubit.state.failureOption.toNullable(),
        isA<UnauthorizedAccessFailure>(),
      );
    });
  });
}
