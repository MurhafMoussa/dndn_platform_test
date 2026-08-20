import 'package:geolocator/geolocator.dart';

import '../models/location_point.dart';

/// Filter utility for dropping GPS noise, urban reflections, stationary wander, and impossible jumps.
class LocationPointFilter {
  /// Default minimum displacement in meters required to register genuine movement.
  static const double defaultMinMoveMeters = 15.0;

  /// Default maximum plausible jump in meters between consecutive GPS fixes.
  static const double defaultMaxJumpMeters = 200.0;

  final double minMoveMeters;
  final double maxJumpMeters;

  const LocationPointFilter({
    this.minMoveMeters = defaultMinMoveMeters,
    this.maxJumpMeters = defaultMaxJumpMeters,
  });

  /// Filters a chronological list of [LocationPoint]s to eliminate noise and impossible coordinate spikes.
  List<LocationPoint> filter(List<LocationPoint> points) {
    if (points.length < 2) {
      return points.where((p) => isPlausible(p.latitude, p.longitude)).toList();
    }

    final plausiblePoints = points.where((p) => isPlausible(p.latitude, p.longitude)).toList();
    if (plausiblePoints.length < 2) {
      return plausiblePoints;
    }

    return _collapseJitter(_dropSpikes(plausiblePoints));
  }

  /// Verifies latitude and longitude are within valid geographic bounds.
  static bool isPlausible(double latitude, double longitude) {
    if (latitude.isNaN || latitude.isInfinite || latitude < -90.0 || latitude > 90.0) {
      return false;
    }
    if (longitude.isNaN || longitude.isInfinite || longitude < -180.0 || longitude > 180.0) {
      return false;
    }
    return true;
  }

  /// Evaluates whether movement between two points exceeds the minimum movement threshold.
  bool isMovementSignificant(LocationPoint from, LocationPoint to) {
    if (!isPlausible(from.latitude, from.longitude) || !isPlausible(to.latitude, to.longitude)) {
      return false;
    }
    final distance = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return distance >= minMoveMeters && distance <= maxJumpMeters;
  }

  List<LocationPoint> _dropSpikes(List<LocationPoint> points) {
    final result = <LocationPoint>[points.first];
    for (int i = 1; i < points.length; i++) {
      final current = points[i];
      final previous = result.last;

      final distance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        current.latitude,
        current.longitude,
      );

      // Drop fixes that represent impossible instantaneous jumps (> maxJumpMeters)
      if (distance <= maxJumpMeters) {
        result.add(current);
      }
    }
    return result;
  }

  List<LocationPoint> _collapseJitter(List<LocationPoint> points) {
    if (points.isEmpty) return const [];

    final result = <LocationPoint>[points.first];
    var anchor = points.first;

    for (int i = 1; i < points.length; i++) {
      final point = points[i];

      final distanceToAnchor = Geolocator.distanceBetween(
        anchor.latitude,
        anchor.longitude,
        point.latitude,
        point.longitude,
      );

      final distanceToLast = Geolocator.distanceBetween(
        result.last.latitude,
        result.last.longitude,
        point.latitude,
        point.longitude,
      );

      // Require significant movement away from both anchor and last accepted point
      if (distanceToAnchor >= minMoveMeters && distanceToLast >= minMoveMeters) {
        result.add(point);
        anchor = point;
      }
    }

    return result;
  }
}
