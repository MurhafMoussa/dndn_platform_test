import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../domain/failures/tracking_failure.dart';
import '../../domain/models/location_point.dart';

/// Service managing foreground and background GPS location streams and permission checks.
class LocationService {
  final GeolocatorPlatform _geolocator;
  final Uuid _uuid;

  /// Default location settings with 2-second interval, 1-meter displacement filter, and native background notification configs.
  static LocationSettings get defaultLocationSettings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Background Location Tracking',
          notificationText: 'Location tracking is active in background.',
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          enableWakeLock: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 1,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
  }

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

  /// Opens native device location settings so the user can enable GPS services.
  Future<bool> openLocationSettings() async {
    try {
      return await _geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Gets single current location fix.
  Future<Either<TrackingFailure, LocationPoint>> getCurrentLocation({
    LocationSettings? locationSettings,
  }) async {
    final settings = locationSettings ?? defaultLocationSettings;
    final permissionCheck = await checkAndRequestPermission();
    return permissionCheck.fold(
      Left.new,
      (_) async {
        try {
          final position = await _geolocator.getCurrentPosition(
            locationSettings: settings,
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
    LocationSettings? locationSettings,
  }) async* {
    final settings = locationSettings ?? defaultLocationSettings;
    final permissionCheck = await checkAndRequestPermission();
    if (permissionCheck.isLeft()) {
      final failure = permissionCheck.getLeft().toNullable() ?? const LocationServiceDisabledFailure();
      yield Left(failure);
      return;
    }

    try {
      await for (final position in _geolocator.getPositionStream(
        locationSettings: settings,
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
      if (e is LocationServiceDisabledException) {
        yield const Left(LocationServiceDisabledFailure());
      } else {
        yield Left(
          LocationPermissionDeniedFailure(
            message: 'Location stream error: ${e.toString()}',
            cause: e,
          ),
        );
      }
    }
  }
}
