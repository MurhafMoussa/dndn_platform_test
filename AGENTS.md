# Project Engineering Rules

## Project

This is a production-oriented Flutter application demonstrating:

- MVVM architecture
- Offline-first data management
- Background location tracking
- Local persistence
- Remote synchronization
- Automated testing
- Atomic Conventional Commits

## Architecture

Use MVVM.

The presentation layer consists of:

- Views
- ViewModels

ViewModels may use Cubit/BLoC as the state-management implementation.

Views must never access repositories or data sources directly.

ViewModels must communicate with the data layer through repository contracts.

Repositories are responsible for coordinating local and remote data sources.

Background services must never depend on Views or ViewModels.

## Data

Use Drift/SQLite as the persistent local database.

Do not use HydratedBloc as the primary application database.

Persistent business/application data must go through the repository.

## Offline First

The local database is the primary source of truth for application data.

Reads should prefer local persisted data.

Offline writes must be persisted locally before synchronization.

Use an outbox for mutations that need remote synchronization.

Network synchronization must not be required for the UI to display locally persisted data.

## Testing

Every production feature must include appropriate tests.

Unit tests:
- models
- serialization
- repository logic
- synchronization logic
- ViewModels

Integration tests:
- database
- repository + database
- synchronization

E2E tests:
- critical user journeys only

Do not delete or weaken tests to make implementation pass.

## Implementation

Never implement an entire feature in one uncontrolled operation.

Follow:

SPEC → PLAN → TASKS → IMPLEMENT → TEST → VERIFY → REVIEW → COMMIT

Before implementing a task:

1. Read the relevant specification.
2. Read the architecture plan.
3. Inspect the existing implementation.
4. Make the smallest required change.

Do not refactor unrelated code.

Do not introduce new dependencies without explaining why.

Do not introduce unnecessary abstractions.

## Git

Use Conventional Commits.

Examples:

feat(tracking): add location point model
test(tracking): add repository tests
feat(sync): add tracking outbox
fix(sync): handle failed synchronization

Keep commits atomic.

Never commit:

- failing tests
- analyzer errors
- unrelated changes
- generated files that should be ignored

Never run `git push` without explicit user approval.

## Verification

Before considering a task complete:

flutter analyze
flutter test

Run focused tests first, then the complete test suite.

Report:

- files changed
- tests added
- tests executed
- analyzer result
- remaining concerns