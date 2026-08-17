import 'dart:async';
import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../../domain/failures/tracking_failure.dart';
import '../../domain/models/incident_report.dart';
import '../../domain/models/location_point.dart';
import '../../domain/models/sync_outbox_item.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../../domain/utils/distance_calculator.dart';
import '../database/tracking_database.dart';
import '../sync/sync_engine.dart';

/// Concrete implementation of [TrackingRepository] coordinating Drift database storage and outbox [SyncEngine].
class TrackingRepositoryImpl implements TrackingRepository {
  /// Local SQLite Drift database instance.
  final TrackingDatabase database;

  /// Outbox sync engine instance.
  final SyncEngine syncEngine;

  TrackingRepositoryImpl({
    required this.database,
    required this.syncEngine,
  });

  @override
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints() {
    return database.watchAllLocationPoints().map<Either<TrackingFailure, List<LocationPoint>>>(
      (rows) {
        try {
          final points = rows
              .map(
                (row) => LocationPoint(
                  id: row.id,
                  latitude: row.latitude,
                  longitude: row.longitude,
                  timestamp: DateTime.fromMillisecondsSinceEpoch(row.timestamp),
                ),
              )
              .toList();
          return Right(points);
        } catch (e) {
          return Left(DatabaseFailure('Error parsing location points from database', e));
        }
      },
    ).handleError((Object error) {
      return Left<TrackingFailure, List<LocationPoint>>(
        DatabaseFailure('Database location points stream error: ${error.toString()}', error),
      );
    });
  }

  @override
  Stream<Either<TrackingFailure, List<IncidentReport>>> watchIncidents() {
    return database.watchAllIncidents().map<Either<TrackingFailure, List<IncidentReport>>>(
      (rows) {
        try {
          final incidents = rows.map((row) {
            final typeEnum = IncidentType.values.firstWhere(
              (e) => e.name == row.type,
              orElse: () => IncidentType.police,
            );
            return IncidentReport(
              id: row.id,
              type: typeEnum,
              latitude: row.latitude,
              longitude: row.longitude,
              timestamp: DateTime.fromMillisecondsSinceEpoch(row.timestamp),
            );
          }).toList();
          return Right(incidents);
        } catch (e) {
          return Left(DatabaseFailure('Error parsing incident reports from database', e));
        }
      },
    ).handleError((Object error) {
      return Left<TrackingFailure, List<IncidentReport>>(
        DatabaseFailure('Database incident stream error: ${error.toString()}', error),
      );
    });
  }

  @override
  Stream<Either<TrackingFailure, List<SyncOutboxItem>>> watchPendingOutbox() {
    return database.watchPendingOutbox().map<Either<TrackingFailure, List<SyncOutboxItem>>>(
      (rows) {
        try {
          final items = rows.map((row) {
            final statusEnum = SyncStatus.values.firstWhere(
              (e) => e.name == row.status,
              orElse: () => SyncStatus.pending,
            );
            return SyncOutboxItem(
              id: row.id,
              eventType: row.eventType,
              payload: row.payload,
              createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
              status: statusEnum,
            );
          }).toList();
          return Right(items);
        } catch (e) {
          return Left(DatabaseFailure('Error parsing outbox items from database', e));
        }
      },
    ).handleError((Object error) {
      return Left<TrackingFailure, List<SyncOutboxItem>>(
        DatabaseFailure('Database outbox stream error: ${error.toString()}', error),
      );
    });
  }

  @override
  Future<Either<TrackingFailure, Unit>> addLocationPoint(LocationPoint point) async {
    try {
      final payloadMap = {
        'id': point.id,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'timestamp': point.timestamp.millisecondsSinceEpoch,
      };

      await database.transaction(() async {
        await database.insertLocationPoint(
          LocationPointsCompanion.insert(
            id: point.id,
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: point.timestamp.millisecondsSinceEpoch,
          ),
        );

        await database.insertOutboxItem(
          SyncOutboxCompanion.insert(
            id: point.id,
            eventType: 'location_point_created',
            payload: jsonEncode(payloadMap),
            createdAt: point.timestamp.millisecondsSinceEpoch,
            status: 'pending',
          ),
        );
      });

      // Trigger asynchronous background flush
      unawaited(syncEngine.flushPendingOutbox());

      return const Right(unit);
    } catch (e) {
      return Left(
        DatabaseFailure(
          'Failed to record location point and enqueue outbox payload: ${e.toString()}',
          e,
        ),
      );
    }
  }

  @override
  Future<Either<TrackingFailure, Unit>> addIncidentReport(IncidentReport incident) async {
    try {
      final payloadMap = {
        'id': incident.id,
        'type': incident.type.name,
        'latitude': incident.latitude,
        'longitude': incident.longitude,
        'timestamp': incident.timestamp.millisecondsSinceEpoch,
      };

      await database.transaction(() async {
        await database.insertIncident(
          IncidentsCompanion.insert(
            id: incident.id,
            type: incident.type.name,
            latitude: incident.latitude,
            longitude: incident.longitude,
            timestamp: incident.timestamp.millisecondsSinceEpoch,
          ),
        );

        await database.insertOutboxItem(
          SyncOutboxCompanion.insert(
            id: incident.id,
            eventType: 'incident_reported',
            payload: jsonEncode(payloadMap),
            createdAt: incident.timestamp.millisecondsSinceEpoch,
            status: 'pending',
          ),
        );
      });

      // Trigger asynchronous background flush
      unawaited(syncEngine.flushPendingOutbox());

      return const Right(unit);
    } catch (e) {
      return Left(
        DatabaseFailure(
          'Failed to submit incident report and enqueue outbox payload: ${e.toString()}',
          e,
        ),
      );
    }
  }

  @override
  TaskEither<TrackingFailure, double> getTotalDistanceMeters() {
    return TaskEither<TrackingFailure, double>(() async {
      try {
        final rows = await database.getAllLocationPoints();
        final points = rows
            .map(
              (row) => LocationPoint(
                id: row.id,
                latitude: row.latitude,
                longitude: row.longitude,
                timestamp: DateTime.fromMillisecondsSinceEpoch(row.timestamp),
              ),
            )
            .toList();

        return DistanceCalculator.calculateTotalDistance(points);
      } catch (e) {
        return Left(
          DatabaseFailure(
            'Failed to retrieve location points for distance calculation: ${e.toString()}',
            e,
          ),
        );
      }
    });
  }

  @override
  Future<Either<TrackingFailure, Unit>> flushOutbox() async {
    final result = await syncEngine.flushPendingOutbox();
    return result.map((_) => unit);
  }
}
