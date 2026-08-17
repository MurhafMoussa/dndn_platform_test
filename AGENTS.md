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

### Dependency Direction

Dependencies must flow inward:

View
→ ViewModel
→ Repository Contract
→ Data Sources
→ Infrastructure

Views must never access:

- repositories
- data sources
- databases
- API clients

ViewModels must communicate with the data layer only through repository contracts.

ViewModels must not directly depend on:

- Drift
- SQLite
- Dio
- HTTP clients
- local data sources
- remote data sources

Repositories are responsible for coordinating local and remote data sources.

Data sources are responsible for external I/O and persistence details.

Business logic must not depend on Flutter UI concerns.

Background services must never depend on Views or ViewModels.

Do not introduce additional architectural layers unless the feature genuinely requires them.

## UI Architecture

Views are responsible for:

- rendering state
- collecting user interaction
- composing widgets
- displaying loading/error/empty/success states

Views must not:

- perform business logic
- call repositories
- access databases
- call APIs
- perform synchronization
- contain complex application workflows

ViewModels are responsible for:

- presentation state
- user-intent handling
- coordinating application behavior
- exposing UI-ready state

Keep ViewModels independent from concrete infrastructure implementations.

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

Synchronization should be idempotent where possible.

Retries must not create duplicate business records.

Synchronization failures must preserve locally persisted user data.

The UI must remain usable when the network is unavailable unless the feature explicitly requires connectivity.

## Flutter

- Follow official Flutter and Dart best practices.
- Prefer const constructors wherever applicable.
- Keep widgets focused and composable.
- Avoid unnecessary widget rebuilds.
- Dispose controllers, animations, streams, subscriptions, and other owned resources.
- Respect Flutter lifecycle rules.
- Prefer declarative UI and composition.
- Avoid business logic inside widgets.
- Avoid direct infrastructure access from widgets.
- Handle asynchronous operations safely.
- Use keys intentionally when identity matters.
- Avoid unnecessary widget nesting.
- Prefer existing project components over creating duplicates.
- Follow accessibility and responsive-layout practices.

## Dart

- Follow Dart null-safety conventions.
- Prefer immutable data where practical.
- Use meaningful and intention-revealing names.
- Avoid unnecessary nullable values.
- Avoid unnecessary type casts.
- Do not ignore returned Futures without an explicit reason.
- Handle asynchronous errors intentionally.
- Prefer composition over unnecessary inheritance.
- Keep public APIs minimal.
- Avoid unnecessary mutable state.
- Avoid hidden side effects.
- Prefer simple control flow over clever abstractions.

## Clean Code

- Optimize for readability before cleverness.
- Prefer small, focused functions.
- Use meaningful names.
- Avoid duplication.
- Avoid premature abstractions.
- Keep responsibilities explicit.
- Prefer immutable data where practical.
- Avoid hidden side effects.

## Complexity Control

Prefer the simplest design that satisfies the requirements.

Do not introduce:

- unnecessary abstractions
- unnecessary interfaces
- unnecessary design patterns
- speculative extensibility
- generic frameworks
- wrapper classes without meaningful behavior
- additional architectural layers

An abstraction must have a concrete reason to exist.

Do not optimize for theoretical future requirements that are not present in the specification.

## UI/UX

- Follow the existing design system before introducing new styles.
- Reuse existing components.
- Do not hardcode arbitrary colors, spacing, typography, or dimensions when design tokens exist.
- Handle loading, empty, error, and success states.
- Consider retry behavior.
- Consider offline state where applicable.
- Ensure layouts work across supported screen sizes.
- Consider accessibility.
- Do not silently treat an error as an empty state.

## Testing

Every production feature must include appropriate tests.

Tests should verify behavior rather than implementation details.

### Unit Tests

Use for:

- models
- serialization
- repository logic
- synchronization logic
- ViewModels
- business rules

### Widget Tests

Use for:

- important UI behavior
- state rendering
- user interactions
- loading/error/empty states
- accessibility behavior where appropriate

### Integration Tests

Use for:

- database
- repository + database
- synchronization
- important cross-layer behavior

### E2E Tests

Use only for critical user journeys.

Do not require E2E tests for every feature.

Do not delete or weaken tests to make implementation pass.

## Generated Code

Do not manually modify generated files unless explicitly required.

When source changes require generated code:

1. Modify the source.
2. Run the appropriate generator.
3. Review generated changes.
4. Do not commit generated files excluded by project conventions.

## Dependencies

Do not add a dependency unless:

1. The requirement cannot reasonably be satisfied with existing dependencies or Dart/Flutter APIs.
2. The dependency provides meaningful value.
3. Its maintenance and complexity cost are justified.
4. The dependency is compatible with the project's architecture.

Prefer existing project dependencies and established project patterns.

## Implementation

Never implement an entire feature in one uncontrolled operation.

Follow:

SPEC → PLAN → TASKS → IMPLEMENT → TEST → REVIEW → VERIFY → COMMIT

Before implementing a task:

1. Read the relevant specification.
2. Read the architecture plan.
3. Inspect the existing implementation.
4. Identify relevant Flutter/Dart skills.
5. Make the smallest required change.

Do not refactor unrelated code.

Do not introduce new dependencies without explaining why.

Do not introduce unnecessary abstractions.

Do not change architecture without updating the architecture plan.

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
- secrets
- temporary/debug files

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