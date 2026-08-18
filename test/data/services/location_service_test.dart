import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dndn_platform_test/data/services/location_service.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permissionStatus = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  Position? currentPosition;
  StreamController<Position> positionStreamController = StreamController<Position>.broadcast();
  LocationSettings? lastLocationSettings;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permissionStatus;

  @override
  Future<LocationPermission> requestPermission() async => requestPermissionResult;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    lastLocationSettings = locationSettings;
    if (currentPosition != null) return currentPosition!;
    throw Exception('No current position available');
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    lastLocationSettings = locationSettings;
    return positionStreamController.stream;
  }
}

void main() {
  late FakeGeolocatorPlatform mockGeolocator;
  late LocationService locationService;

  setUp(() {
    mockGeolocator = FakeGeolocatorPlatform();
    locationService = LocationService(geolocator: mockGeolocator);
  });

  tearDown(() {
    mockGeolocator.positionStreamController.close();
  });

  group('LocationService', () {
    test('defaultLocationSettings configures 2s interval and 1m distance filter', () {
      expect(LocationService.defaultLocationSettings.accuracy, equals(LocationAccuracy.high));
      expect(LocationService.defaultLocationSettings.distanceFilter, equals(1));
    });

    test('yields LocationServiceDisabledFailure when GPS service is disabled', () async {
      mockGeolocator.serviceEnabled = false;

      final result = await locationService.checkAndRequestPermission();
      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<LocationServiceDisabledFailure>()),
        (_) => fail('Should yield failure'),
      );
    });

    test('yields LocationPermissionDeniedFailure when permission denied', () async {
      mockGeolocator.serviceEnabled = true;
      mockGeolocator.permissionStatus = LocationPermission.denied;
      mockGeolocator.requestPermissionResult = LocationPermission.denied;

      final result = await locationService.checkAndRequestPermission();
      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<LocationPermissionDeniedFailure>());
          final permFailure = failure as LocationPermissionDeniedFailure;
          expect(permFailure.isPermanentlyDenied, isFalse);
        },
        (_) => fail('Should yield failure'),
      );
    });

    test('yields LocationPermissionDeniedFailure with isPermanentlyDenied when deniedForever', () async {
      mockGeolocator.serviceEnabled = true;
      mockGeolocator.permissionStatus = LocationPermission.deniedForever;

      final result = await locationService.checkAndRequestPermission();
      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<LocationPermissionDeniedFailure>());
          final permFailure = failure as LocationPermissionDeniedFailure;
          expect(permFailure.isPermanentlyDenied, isTrue);
        },
        (_) => fail('Should yield failure'),
      );
    });

    test('streams LocationPoint when permissions are granted', () async {
      mockGeolocator.serviceEnabled = true;
      mockGeolocator.permissionStatus = LocationPermission.whileInUse;

      final now = DateTime.now();
      final pos = Position(
        longitude: 20.0,
        latitude: 10.0,
        timestamp: now,
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final streamFuture = locationService.getLocationStream().first;

      // Allow async permission checks in getLocationStream() to subscribe to stream before pushing pos
      await Future<void>.delayed(const Duration(milliseconds: 50));
      mockGeolocator.positionStreamController.add(pos);

      final firstEmit = await streamFuture;
      expect(firstEmit.isRight(), isTrue);
      firstEmit.match(
        (failure) => fail('Should succeed'),
        (point) {
          expect(point.latitude, equals(10.0));
          expect(point.longitude, equals(20.0));
          expect(point.timestamp, equals(now));
        },
      );

      expect(mockGeolocator.lastLocationSettings?.distanceFilter, equals(1));
    });

    test('getCurrentLocation returns LocationPoint when permissions are granted', () async {
      mockGeolocator.serviceEnabled = true;
      mockGeolocator.permissionStatus = LocationPermission.whileInUse;

      final now = DateTime.now();
      mockGeolocator.currentPosition = Position(
        longitude: -122.4194,
        latitude: 37.7749,
        timestamp: now,
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final result = await locationService.getCurrentLocation();
      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Should succeed'),
        (point) {
          expect(point.latitude, equals(37.7749));
          expect(point.longitude, equals(-122.4194));
        },
      );
    });
  });
}
