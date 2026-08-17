import 'dart:async';
import 'dart:developer' as developer;

import 'package:fpdart/fpdart.dart';
import '../../domain/failures/tracking_failure.dart';
import '../database/tracking_database.dart';

/// Function signature for dispatching JSON payloads (can be injected for testing/mocking).
typedef Dispatcher = Future<void> Function(String eventType, String payload);

/// Engine responsible for processing enqueued outbox payloads and synchronizing with remote/console dispatch.
class SyncEngine {
  /// Local SQLite Drift database instance.
  final TrackingDatabase database;

  /// Custom payload dispatcher override for unit testing or remote API integration.
  final Dispatcher? customDispatcher;

  /// Simulated delay duration before dispatching payloads.
  final Duration simulatedDelay;

  SyncEngine({
    required this.database,
    this.customDispatcher,
    this.simulatedDelay = Duration.zero,
  });

  /// Default console logger dispatcher simulating real-time WebSocket emission.
  static Future<void> defaultConsoleDispatcher(String eventType, String payload) async {
    // ignore: avoid_print
    print('[DISPATCH] Event: $eventType | Payload: $payload');
    developer.log('Dispatched event $eventType: $payload', name: 'SyncEngine');
  }

  /// Processes all pending outbox entries in chronological order.
  Future<Either<TrackingFailure, int>> flushPendingOutbox() async {
    try {
      final pendingItems = await database.getPendingOutboxItems();
      if (pendingItems.isEmpty) {
        return const Right(0);
      }

      int processedCount = 0;
      final dispatcher = customDispatcher ?? defaultConsoleDispatcher;

      for (final item in pendingItems) {
        // Transition status to 'syncing'
        await database.updateOutboxStatus(item.id, 'syncing');

        try {
          if (simulatedDelay > Duration.zero) {
            await Future<void>.delayed(simulatedDelay);
          }

          // Execute dispatch
          await dispatcher(item.eventType, item.payload);

          // Transition status to 'synced'
          await database.updateOutboxStatus(item.id, 'synced');
          processedCount++;
        } catch (e) {
          // Transition status to 'failed' on error without deleting local record
          await database.updateOutboxStatus(item.id, 'failed');
          return Left(
            SyncFailure(
              'Failed to dispatch outbox item ${item.id}: ${e.toString()}',
              e,
            ),
          );
        }
      }

      return Right(processedCount);
    } catch (e) {
      return Left(
        SyncFailure(
          'Database query error during outbox flush: ${e.toString()}',
          e,
        ),
      );
    }
  }
}
