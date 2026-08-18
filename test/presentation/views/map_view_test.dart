import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:dndn_platform_test/data/services/location_service.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';
import 'package:dndn_platform_test/domain/repositories/tracking_repository.dart';
import 'package:dndn_platform_test/presentation/cubits/incident/incident_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/map/map_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/user_role_cubit.dart';
import 'package:dndn_platform_test/presentation/views/map_view.dart';

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

class FakeTrackingRepository implements TrackingRepository {
  final StreamController<Either<TrackingFailure, List<LocationPoint>>> pointsController =
      StreamController<Either<TrackingFailure, List<LocationPoint>>>.broadcast();

  @override
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints() {
    return pointsController.stream;
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
  Stream<Either<TrackingFailure, List<IncidentReport>>> watchIncidents() {
    return const Stream.empty();
  }

  @override
  Stream<Either<TrackingFailure, List<SyncOutboxItem>>> watchPendingOutbox() {
    return const Stream.empty();
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
  @override
  Stream<Either<TrackingFailure, LocationPoint>> getLocationStream({dynamic locationSettings}) {
    return const Stream.empty();
  }
}

void main() {
  late FakeTrackingRepository repository;
  late FakeLocationService locationService;

  setUp(() {
    HydratedBloc.storage = MockStorage();
    repository = FakeTrackingRepository();
    locationService = FakeLocationService();
  });

  tearDown(() {
    repository.dispose();
  });

  Widget buildSubject({
    required MapCubit mapCubit,
    required IncidentCubit incidentCubit,
    required UserRoleCubit userRoleCubit,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MapView(),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserRoleCubit>.value(value: userRoleCubit),
        BlocProvider<MapCubit>.value(value: mapCubit),
        BlocProvider<IncidentCubit>.value(value: incidentCubit),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('MapView', () {
    testWidgets('renders map view title, map canvas, and Report Hazard FAB', (WidgetTester tester) async {
      final userRoleCubit = UserRoleCubit();
      final mapCubit = MapCubit(repository: repository, locationService: locationService);
      final incidentCubit = IncidentCubit(repository: repository);

      addTearDown(() {
        mapCubit.close();
        incidentCubit.close();
        userRoleCubit.close();
      });

      await tester.pumpWidget(
        buildSubject(
          mapCubit: mapCubit,
          incidentCubit: incidentCubit,
          userRoleCubit: userRoleCubit,
        ),
      );

      repository.pointsController.add(const Right([]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Map & Live Tracking'), findsOneWidget);
      expect(find.text('Report Hazard'), findsOneWidget);
      expect(find.text('GPS Route Breadcrumbs'), findsOneWidget);
    });

    testWidgets('tapping Report Hazard FAB opens IncidentReportDialog', (WidgetTester tester) async {
      final userRoleCubit = UserRoleCubit();
      final mapCubit = MapCubit(repository: repository, locationService: locationService);
      final incidentCubit = IncidentCubit(repository: repository);

      addTearDown(() {
        mapCubit.close();
        incidentCubit.close();
        userRoleCubit.close();
      });

      await tester.pumpWidget(
        buildSubject(
          mapCubit: mapCubit,
          incidentCubit: incidentCubit,
          userRoleCubit: userRoleCubit,
        ),
      );

      repository.pointsController.add(const Right([]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Report Hazard'));
      await tester.pumpAndSettle();

      expect(find.text('Report Incident'), findsOneWidget);
      expect(find.text('Police'), findsOneWidget);
      expect(find.text('Accident'), findsOneWidget);
      expect(find.text('Traffic Heavy'), findsOneWidget);
    });
  });
}
