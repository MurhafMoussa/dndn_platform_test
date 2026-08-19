import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dndn_platform_test/data/services/location_service.dart';
import 'package:dndn_platform_test/presentation/cubits/location_permission/location_permission_cubit.dart';
import 'package:dndn_platform_test/presentation/widgets/location_permission_error_view.dart';
import 'package:dndn_platform_test/presentation/widgets/location_permission_guard.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permissionStatus = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  bool settingsOpened = false;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permissionStatus;

  @override
  Future<LocationPermission> requestPermission() async => requestPermissionResult;

  @override
  Future<bool> openLocationSettings() async {
    settingsOpened = true;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGeolocatorPlatform mockGeolocator;
  late LocationService locationService;
  late LocationPermissionCubit cubit;

  setUp(() {
    mockGeolocator = FakeGeolocatorPlatform();
    locationService = LocationService(geolocator: mockGeolocator);
    cubit = LocationPermissionCubit(locationService: locationService);
  });

  tearDown(() async {
    await cubit.close();
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<LocationPermissionCubit>.value(
        value: cubit,
        child: child,
      ),
    );
  }

  group('LocationPermissionGuard & LocationPermissionErrorView', () {
    testWidgets('renders child widget when permission is granted', (tester) async {
      await cubit.checkPermission();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestWidget(
          const LocationPermissionGuard(
            child: Text('Protected Content'),
          ),
        ),
      );

      expect(find.text('Protected Content'), findsOneWidget);
    });

    testWidgets('renders error view when permission is denied', (tester) async {
      mockGeolocator.permissionStatus = LocationPermission.denied;
      await cubit.checkPermission();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestWidget(
          const LocationPermissionGuard(
            child: Text('Protected Content'),
          ),
        ),
      );

      expect(find.text('Protected Content'), findsNothing);
      expect(find.byType(LocationPermissionErrorView), findsOneWidget);
      expect(find.text('Location Service Failure'), findsOneWidget);
      expect(find.text('Grant Location Permission'), findsOneWidget);
      expect(find.text('Open Location Settings'), findsOneWidget);
    });

    testWidgets('tapping Open Location Settings invokes openLocationSettings on service', (tester) async {
      mockGeolocator.permissionStatus = LocationPermission.denied;
      await cubit.checkPermission();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestWidget(
          const LocationPermissionGuard(
            child: Text('Protected Content'),
          ),
        ),
      );

      await tester.tap(find.text('Open Location Settings'));
      await tester.pumpAndSettle();

      expect(mockGeolocator.settingsOpened, isTrue);
    });
  });
}
