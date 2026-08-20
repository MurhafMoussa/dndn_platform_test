import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';

import '../failures/tracking_failure.dart';
import '../models/location_point.dart';
import 'location_point_filter.dart';

/// Helper utility for computing distance metrics across location points.
class DistanceCalculator {
  const DistanceCalculator._();

  /// Calculates total distance traveled in meters across chronological [points].
  ///
  /// Optional [filter] drops GPS noise jitter and impossible spikes.
  /// Returns [Right(0.0)] if [points] has fewer than 2 elements.
  /// Returns [Left(DistanceCalculationFailure)] if coordinates are invalid or distance calculation fails.
  static Either<TrackingFailure, double> calculateTotalDistance(
    List<LocationPoint> points, {
    LocationPointFilter? filter,
  }) {
    if (points.length < 2) {
      return const Right(0.0);
    }

    try {
      final targetPoints = filter != null ? filter.filter(points) : points;
      if (targetPoints.length < 2) {
        return const Right(0.0);
      }

      double totalDistance = 0.0;
      for (int i = 0; i < targetPoints.length - 1; i++) {
        final p1 = targetPoints[i];
        final p2 = targetPoints[i + 1];

        if (!LocationPointFilter.isPlausible(p1.latitude, p1.longitude) ||
            !LocationPointFilter.isPlausible(p2.latitude, p2.longitude)) {
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
}
