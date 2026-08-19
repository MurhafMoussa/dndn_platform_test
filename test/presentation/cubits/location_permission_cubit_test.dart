import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dndn_platform_test/data/services/location_service.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/presentation/cubits/location_permission/location_permission_cubit.dart';
import 'package:dndn_platform_test/presentation/cubits/location_permission/location_permission_state.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permissionStatus = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  bool openSettingsResult = true;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permissionStatus;

  @override
  Future<LocationPermission> requestPermission() async => requestPermissionResult;

  @override
  Future<bool> openLocationSettings() async => openSettingsResult;
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

  group('LocationPermissionCubit', () {
    test('initial state is LocationPermissionInitial', () {
      expect(cubit.state, equals(const LocationPermissionInitial()));
    });

    test('checkPermission emits Granted when permission is granted and service is enabled', () async {
      mockGeolocator.permissionStatus = LocationPermission.whileInUse;
      mockGeolocator.serviceEnabled = true;

      final futureExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const LocationPermissionLoading(),
          const LocationPermissionGranted(),
        ]),
      );

      await cubit.checkPermission();
      await futureExpectation;
    });

    test('checkPermission emits Denied when permission is denied', () async {
      mockGeolocator.permissionStatus = LocationPermission.denied;

      final futureExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const LocationPermissionLoading(),
          isA<LocationPermissionDenied>().having(
            (s) => s.failure,
            'failure',
            isA<LocationPermissionDeniedFailure>(),
          ),
        ]),
      );

      await cubit.checkPermission();
      await futureExpectation;
    });

    test('checkPermission emits Denied when location service is disabled', () async {
      mockGeolocator.permissionStatus = LocationPermission.whileInUse;
      mockGeolocator.serviceEnabled = false;

      final futureExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const LocationPermissionLoading(),
          isA<LocationPermissionDenied>().having(
            (s) => s.failure,
            'failure',
            isA<LocationServiceDisabledFailure>(),
          ),
        ]),
      );

      await cubit.checkPermission();
      await futureExpectation;
    });

    test('requestPermission invokes checkAndRequestPermission', () async {
      mockGeolocator.permissionStatus = LocationPermission.denied;
      mockGeolocator.requestPermissionResult = LocationPermission.always;
      mockGeolocator.serviceEnabled = true;

      final futureExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const LocationPermissionLoading(),
          const LocationPermissionGranted(),
        ]),
      );

      await cubit.requestPermission();
      await futureExpectation;
    });

    test('didChangeAppLifecycleState on resumed checks permission status', () async {
      mockGeolocator.permissionStatus = LocationPermission.denied;

      final futureExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const LocationPermissionLoading(),
          isA<LocationPermissionDenied>(),
        ]),
      );

      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await futureExpectation;
    });
  });
}
