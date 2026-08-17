---
description: Verify the current implementation using static analysis, tests, architecture checks, and repository state.
---

Perform a verification pass on the current implementation.

Do not make code changes unless explicitly requested.

## Step 1 — Repository State

Run:

git status --short

Inspect the current diff:

git diff --stat
git diff

Identify:

- unexpected files
- generated files
- unrelated changes
- accidental modifications

## Step 2 — Static Analysis

Run:

flutter analyze

Report all errors and warnings.

Do not hide, suppress, or ignore analyzer warnings merely to make verification pass.

## Step 3 — Tests

Run the focused tests relevant to the current feature first.

Then run:

flutter test

If integration tests exist and are relevant, run them separately.

## Step 4 — Architecture

Check:

- Views do not access repositories directly.
- Views do not access data sources.
- ViewModels do not access database implementations directly.
- ViewModels do not access remote data sources directly.
- Repositories coordinate data sources.
- Background services do not depend on presentation classes.
- Offline-first behavior is implemented through persistent local storage.
- Business data is not persisted through HydratedBloc.

## Step 5 — Offline-First Verification

For features requiring offline behavior, verify:

- local data can be read without network access
- writes are persisted locally before synchronization
- synchronization failure does not destroy local data
- pending synchronization work is persisted
- retry behavior is deterministic
- UI state can be restored from local data

## Step 6 — Test Coverage

Check whether the changed behavior has appropriate:

- unit tests
- integration tests
- widget tests where appropriate
- E2E tests for critical user journeys

Do not require E2E tests for every small unit of behavior.

## Output

Return:

### Verification Result

PASS / FAIL

### Analyzer

Result and relevant errors.

### Tests

Tests executed and results.

### Architecture

PASS / FAIL with violations.

### Offline-First

PASS / FAIL with violations.

### Missing Tests

List missing coverage.

### Unexpected Changes

List unrelated changes.

### Recommendation

State whether the implementation is ready for review.

Do not modify code.