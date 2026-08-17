import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';

import '../failures/tracking_failure.dart';
import '../models/location_point.dart';

/// Helper utility for computing distance metrics across location points.
class DistanceCalculator {
  const DistanceCalculator._();

  /// Calculates total distance traveled in meters across chronological [points].
  ///
  /// Returns [Right(0.0)] if [points] has fewer than 2 elements.
  /// Returns [Left(DistanceCalculationFailure)] if coordinates are invalid or distance calculation fails.
  static Either<TrackingFailure, double> calculateTotalDistance(
    List<LocationPoint> points,
  ) {
    if (points.length < 2) {
      return const Right(0.0);
    }

    try {
      double totalDistance = 0.0;
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];

        if (!_isValidCoordinate(p1.latitude, p1.longitude) ||
            !_isValidCoordinate(p2.latitude, p2.longitude)) {
          return const Left(
            DistanceCalculationFailure(
              'Invalid latitude or longitude coordinates encountered in location points.',
            ),
          );
        }

        totalDistance += Geolocator.distanceBetween(
          p1.latitude,
          p1.longitude,
          p2.latitude,
          p2.longitude,
        );
      }

      return Right(totalDistance);
    } catch (e) {
      return Left(
        DistanceCalculationFailure(
          'Failed to compute total distance traveled: ${e.toString()}',
          e,
        ),
      );
    }
  }

  static bool _isValidCoordinate(double latitude, double longitude) {
    if (latitude.isNaN || latitude.isInfinite || latitude < -90.0 || latitude > 90.0) {
      return false;
    }
    if (longitude.isNaN || longitude.isInfinite || longitude < -180.0 || longitude > 180.0) {
      return false;
    }
    return true;
  }
}
