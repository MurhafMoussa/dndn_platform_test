---
description: Perform a senior engineering review of the current changes without modifying code.
---

You are reviewing a pull request for a production-oriented Flutter application.

Do not modify any files.

First inspect:

1. AGENTS.md
2. Relevant feature specification
3. Relevant architecture plan
4. Current git diff
5. Relevant tests
6. Existing surrounding implementation

Review the changes only within their actual scope.

## Review Criteria

### 1. Correctness

Check:

- Does the implementation satisfy the specification?
- Are edge cases handled?
- Are failures handled correctly?
- Is state management deterministic?

### 2. Architecture

Check:

- MVVM boundaries
- View/ViewModel responsibilities
- Repository boundaries
- Data source responsibilities
- Dependency direction
- Background service isolation

Reject unnecessary architectural complexity.

### 3. Offline-First

Check:

- local-first reads
- local persistence before remote synchronization
- synchronization failures
- retry behavior
- persistence across application restarts
- duplicate synchronization risks

### 4. Flutter

Check:

- lifecycle handling
- async behavior
- disposed resources
- unnecessary rebuilds
- state ownership
- platform-specific concerns
### 5. UI / UX

Check:

- consistency with existing design system
- reuse of existing widgets/components
- loading states
- empty states
- error states
- disabled states
- responsive layouts
- accessibility
- semantic widgets where appropriate
- keyboard behavior
- text overflow
- layout overflow
- platform-specific behavior
- unnecessary hardcoded visual values
- inappropriate widget composition

### 6. Testing

Check whether tests verify behavior rather than implementation details.

Look for:

- missing edge cases
- brittle tests
- excessive mocking
- tests that provide little value
- missing integration coverage

### 7. Maintainability

Check:

- naming
- cohesion
- coupling
- duplication
- unnecessary abstractions
- overly large classes/functions
- unclear responsibilities

### 8. Scope

Check for:

- unrelated refactoring
- unnecessary dependencies
- unnecessary files
- changes outside the requested feature

### 9. Dart

Check:

- null-safety
- unnecessary nullable values
- async/await correctness
- Future/Stream handling
- error propagation
- unnecessary mutable state
- unnecessary allocations
- naming
- API clarity
- unnecessary complexity
- unsafe casts
- ignored Futures
- resource lifecycle
## Severity

Classify findings as:

BLOCKER
Must be fixed before approval.

IMPORTANT
Should be fixed before merging.

SUGGESTION
Improvement that is not required.

## Output

### Summary

One paragraph.

### Blockers

List with file and reason.

### Important Issues

List with file and reason.

### Suggestions

List with file and reason.

### Missing Tests

List missing behavioral coverage.

### Positive Aspects

Mention genuinely good engineering decisions.

### Verdict

APPROVE
or
REQUEST CHANGES

Do not modify the repository.