import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/user_role.dart';
import 'package:dndn_platform_test/presentation/cubits/user_role_cubit.dart';
import 'package:dndn_platform_test/presentation/widgets/app_navigation_drawer.dart';
import 'package:dndn_platform_test/presentation/widgets/incident_report_dialog.dart';
import 'package:dndn_platform_test/presentation/widgets/incidents_table.dart';
import 'package:dndn_platform_test/presentation/widgets/telemetry_card.dart';

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
  setUp(() {
    HydratedBloc.storage = MockStorage();
  });

  group('TelemetryCard', () {
    testWidgets('renders icon, title, and formatted value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelemetryCard(
              icon: Icons.straighten_rounded,
              title: 'Total Distance',
              value: '1,250 m',
            ),
          ),
        ),
      );

      expect(find.text('Total Distance'), findsOneWidget);
      expect(find.text('1,250 m'), findsOneWidget);
      expect(find.byIcon(Icons.straighten_rounded), findsOneWidget);
    });
  });

  group('IncidentsTable', () {
    testWidgets('renders empty state when incidents list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IncidentsTable(incidents: []),
          ),
        ),
      );

      expect(find.text('No Incident Reports Logged'), findsOneWidget);
    });

    testWidgets('renders table headers and row cells when incidents are present', (WidgetTester tester) async {
      final now = DateTime(2026, 8, 17, 14, 30, 0);
      final incident = IncidentReport(
        id: 'inc1',
        type: IncidentType.police,
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncidentsTable(incidents: [incident]),
          ),
        ),
      );

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Timestamp'), findsOneWidget);
      expect(find.text('Police'), findsOneWidget);
      expect(find.text('2026-08-17 14:30:00'), findsOneWidget);
      expect(find.text('37.7749'), findsOneWidget);
      expect(find.text('-122.4194'), findsOneWidget);
    });
  });

  group('IncidentReportDialog', () {
    testWidgets('presents 3 choices: Police, Accident, Traffic Heavy', (WidgetTester tester) async {
      IncidentType? selectedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => IncidentReportDialog(
                        onSelectIncident: (type) {
                          selectedType = type;
                        },
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Report Incident'), findsOneWidget);
      expect(find.text('Police'), findsOneWidget);
      expect(find.text('Accident'), findsOneWidget);
      expect(find.text('Traffic Heavy'), findsOneWidget);

      await tester.tap(find.text('Police'));
      await tester.pumpAndSettle();

      expect(selectedType, equals(IncidentType.police));
    });
  });

  group('AppNavigationDrawer', () {
    testWidgets('renders drawer items and toggles UserRole', (WidgetTester tester) async {
      final userRoleCubit = UserRoleCubit();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              drawer: AppNavigationDrawer(currentRoute: '/'),
              body: Center(child: Text('Main Content')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<UserRoleCubit>.value(
          value: userRoleCubit,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Open drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Location & Telemetry'), findsOneWidget);
      expect(find.text('Map & Tracking'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('User Session'), findsOneWidget);

      // Toggle switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(userRoleCubit.state, equals(UserRole.admin));
      expect(find.text('Admin Session'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await userRoleCubit.close();
    });
  });
}
