import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../domain/failures/tracking_failure.dart';
import '../../domain/models/location_point.dart';

/// Service managing foreground and background GPS location streams and permission checks.
class LocationService {
  final GeolocatorPlatform _geolocator;
  final Uuid _uuid;

  /// Default location settings with 2-second interval and 1-meter displacement filter.
  static const LocationSettings defaultLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1,
    timeLimit: Duration(seconds: 2),
  );

  LocationService({
    GeolocatorPlatform? geolocator,
    Uuid? uuid,
  })  : _geolocator = geolocator ?? GeolocatorPlatform.instance,
        _uuid = uuid ?? const Uuid();

  /// Verifies GPS service availability and permission status.
  Future<Either<TrackingFailure, Unit>> checkAndRequestPermission() async {
    try {
      final serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(LocationServiceDisabledFailure());
      }

      LocationPermission permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left(
            LocationPermissionDeniedFailure(
              message: 'Location permission was denied by user.',
              isPermanentlyDenied: false,
            ),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left(
          LocationPermissionDeniedFailure(
            message: 'Location permission is permanently denied in settings.',
            isPermanentlyDenied: true,
          ),
        );
      }

      return const Right(unit);
    } catch (e) {
      return Left(
        LocationPermissionDeniedFailure(
          message: 'Failed to verify location permissions: ${e.toString()}',
          cause: e,
        ),
      );
    }
  }

  /// Gets single current location fix.
  Future<Either<TrackingFailure, LocationPoint>> getCurrentLocation({
    LocationSettings locationSettings = defaultLocationSettings,
  }) async {
    final permissionCheck = await checkAndRequestPermission();
    return permissionCheck.fold(
      Left.new,
      (_) async {
        try {
          final position = await _geolocator.getCurrentPosition(
            locationSettings: locationSettings,
          );
          final point = LocationPoint(
            id: _uuid.v4(),
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: position.timestamp,
          );
          return Right(point);
        } catch (e) {
          return Left(
            LocationPermissionDeniedFailure(
              message: 'Error acquiring current GPS position: ${e.toString()}',
              cause: e,
            ),
          );
        }
      },
    );
  }

  /// Exposes stream of periodic GPS position updates mapped to [LocationPoint].
  Stream<Either<TrackingFailure, LocationPoint>> getLocationStream({
    LocationSettings locationSettings = defaultLocationSettings,
  }) async* {
    final permissionCheck = await checkAndRequestPermission();
    if (permissionCheck.isLeft()) {
      final failure = permissionCheck.getLeft().toNullable() ?? const LocationServiceDisabledFailure();
      yield Left(failure);
      return;
    }

    try {
      await for (final position in _geolocator.getPositionStream(
        locationSettings: locationSettings,
      )) {
        yield Right(
          LocationPoint(
            id: _uuid.v4(),
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: position.timestamp,
          ),
        );
      }
    } catch (e) {
      yield Left(
        LocationPermissionDeniedFailure(
          message: 'Location stream error: ${e.toString()}',
          cause: e,
        ),
      );
    }
  }
}
