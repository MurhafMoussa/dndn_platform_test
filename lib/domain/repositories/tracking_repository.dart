import 'package:fpdart/fpdart.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';

/// Contract interface for location tracking, incident reporting, and offline outbox sync.
abstract class TrackingRepository {
  /// Stream of chronologically ordered location points wrapped in [Either].
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints();

  /// Stream of incident reports wrapped in [Either].
  Stream<Either<TrackingFailure, List<IncidentReport>>> watchIncidents();

  /// Stream of pending outbox items wrapped in [Either].
  Stream<Either<TrackingFailure, List<SyncOutboxItem>>> watchPendingOutbox();

  /// Atomic operation: Persist location point locally and enqueue sync_outbox item.
  Future<Either<TrackingFailure, Unit>> addLocationPoint(LocationPoint point);

  /// Atomic operation: Persist incident report locally and enqueue sync_outbox item.
  Future<Either<TrackingFailure, Unit>> addIncidentReport(IncidentReport incident);

  /// Computes total distance traveled in meters across all recorded points using [TaskEither].
  TaskEither<TrackingFailure, double> getTotalDistanceMeters();

  /// Processes pending outbox items and updates outbox state.
  Future<Either<TrackingFailure, Unit>> flushOutbox();
}
