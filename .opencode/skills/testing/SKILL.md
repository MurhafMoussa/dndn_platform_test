---
name: testing
description: Testing strategy and conventions for the Flutter application.
---

# Testing Strategy

Tests should verify observable behavior and important architectural guarantees.

Prefer meaningful tests over high test counts.

## Testing Pyramid

Use:

1. Unit tests
2. Widget tests
3. Integration tests
4. E2E tests for critical user journeys

Do not automatically create every test type for every change.

## Unit Tests

Use unit tests for:

- models
- serialization
- repository behavior
- synchronization logic
- retry logic
- data transformations
- ViewModel state transitions
- pure business logic

Tests should cover:

- happy path
- expected failures
- important edge cases

## Widget Tests

Use widget tests for:

- user interactions
- rendering important UI states
- dialogs
- buttons
- loading/error/success states
- View ↔ ViewModel interaction

Avoid testing Flutter framework behavior.

Avoid excessive implementation-detail assertions.

## Integration Tests

Use integration tests for boundaries such as:

- repository + local database
- persistence + application restart
- synchronization flow
- local database + sync engine

Prefer real local infrastructure where practical.

Do not mock the component being tested.

## E2E Tests

Use E2E tests only for critical user journeys.

For this application, prioritize:

1. Launch application.
2. Permission handling.
3. Start tracking.
4. Record location points.
5. Report an incident.
6. Persist data offline.
7. Restore persisted data.
8. Synchronize when connectivity becomes available.

Keep E2E tests small and deterministic.

## Offline-First Testing

Every offline-first feature should verify:

ONLINE

operation succeeds normally.

OFFLINE

operation remains usable where the specification requires offline support.

PERSISTENCE

locally created data survives application restart where required.

SYNC

pending data is synchronized when connectivity returns.

FAILURE

synchronization failure does not lose local data.

RETRY

retry behavior works as specified.

## Test Doubles

Prefer:

- fakes for deterministic infrastructure
- mocks for interaction verification where useful

Create interfaces only when they provide a meaningful testing or architectural boundary.

Do not introduce abstractions solely to make mocking possible.

## Rules

Never:

- delete a test to make the implementation pass
- weaken an assertion without justification
- mock everything
- test implementation details unnecessarily
- create E2E tests for trivial logic

Every test should answer:

"What behavior would break if this test failed?"