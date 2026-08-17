---
name: offline-first
description: Implement and review offline-first persistence, synchronization, outbox processing, and local-first reads for the Flutter application.
---

# Offline First

The local database is the source of truth.

## Reads

UI reads from local persisted state.

Remote synchronization updates the local database.

The UI observes the local database rather than depending directly on the network.

## Writes

For offline-capable mutations:

1. Validate the operation.
2. Persist the local change.
3. Persist an outbox operation if remote synchronization is required.
4. Update the UI from local state.
5. Synchronize when connectivity is available.

## Sync

The sync engine:

- reads pending outbox operations
- sends them to the remote API
- handles success
- handles retryable failures
- records retry metadata
- prevents duplicate processing where required

## Failure

Network failure must not destroy locally persisted user data.

Never delete local data merely because synchronization failed.

## Location Tracking

GPS points must be persisted locally before relying on remote delivery.

Background tracking must continue to work without network connectivity.

## Important

Do not store large collections of business data in HydratedBloc.

Use Drift/SQLite.