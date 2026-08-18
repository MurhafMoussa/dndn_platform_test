import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';
import 'package:dndn_platform_test/domain/models/user_role.dart';
import 'package:dndn_platform_test/domain/repositories/tracking_repository.dart';
import 'package:dndn_platform_test/presentation/cubits/admin/admin_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/user_role_cubit.dart';
import 'package:dndn_platform_test/presentation/views/admin_view.dart';

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

  final StreamController<Either<TrackingFailure, List<IncidentReport>>> incidentsController =
      StreamController<Either<TrackingFailure, List<IncidentReport>>>.broadcast();

  double calculatedDistance = 1250.0;

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
  late FakeTrackingRepository repository;

  setUp(() {
    HydratedBloc.storage = MockStorage();
    repository = FakeTrackingRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  Widget buildSubject({
    required UserRoleCubit userRoleCubit,
    required AdminCubit adminCubit,
  }) {
    final router = GoRouter(
      initialLocation: '/admin',
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminView(),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserRoleCubit>.value(value: userRoleCubit),
        BlocProvider<AdminCubit>.value(value: adminCubit),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('AdminView', () {
    testWidgets('renders UnauthorizedView when user role is UserRole.user', (WidgetTester tester) async {
      final userRoleCubit = UserRoleCubit(); // defaults to UserRole.user
      final adminCubit = AdminCubit(repository: repository);

      addTearDown(() {
        adminCubit.close();
        userRoleCubit.close();
      });

      await tester.pumpWidget(
        buildSubject(
          userRoleCubit: userRoleCubit,
          adminCubit: adminCubit,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Unauthorized Access'), findsOneWidget);
    });

    testWidgets('renders telemetry dashboard and incidents table when user role is UserRole.admin', (WidgetTester tester) async {
      final userRoleCubit = UserRoleCubit();
      userRoleCubit.setRole(UserRole.admin);

      final adminCubit = AdminCubit(repository: repository);

      addTearDown(() {
        adminCubit.close();
        userRoleCubit.close();
      });

      await tester.pumpWidget(
        buildSubject(
          userRoleCubit: userRoleCubit,
          adminCubit: adminCubit,
        ),
      );
      await tester.pump();

      final now = DateTime.now();
      final p1 = LocationPoint(id: 'p1', latitude: 0, longitude: 0, timestamp: now);
      final inc1 = IncidentReport(
        id: 'inc1',
        type: IncidentType.police,
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      repository.pointsController.add(Right([p1]));
      repository.incidentsController.add(Right([inc1]));

      await tester.pumpAndSettle();

      expect(find.text('Admin Telemetry Dashboard'), findsOneWidget);
      expect(find.text('Total Distance Traveled'), findsNWidgets(2));
      expect(find.text('1,250 m'), findsOneWidget);
      expect(find.text('Total Location Points'), findsNWidgets(2));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Telemetry Metrics Explanation'), findsOneWidget);
      expect(find.text('Incident Reports Log'), findsOneWidget);
      expect(find.text('Police'), findsOneWidget);
    });
  });
}
