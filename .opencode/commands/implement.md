---
description: Implement one approved engineering task using the project's architecture and Flutter/Dart best practices.
---

Implement ONLY the specified task.

Before editing:

1. Read AGENTS.md.
2. Read the relevant feature specification.
3. Read the architecture plan.
4. Read the relevant task.
5. Inspect the existing implementation.
6. Identify relevant Flutter/Dart skills.
7. Inspect existing reusable components, patterns, and abstractions.

Do not implement until the task, architecture, and existing patterns are understood.

## Implementation Principles

Follow:

- The approved architecture plan.
- The project's AGENTS.md rules.
- Official Flutter best practices.
- Official Dart best practices.
- Existing project conventions.
- Existing UI/design-system conventions.

Prefer:

- existing abstractions over creating duplicates
- composition over unnecessary inheritance
- immutable state where appropriate
- const widgets where appropriate
- small cohesive functions/classes
- explicit dependencies
- testable business logic
- reusable UI components
- semantic and accessible Flutter widgets

Do not:

- modify unrelated files
- refactor unrelated code
- introduce dependencies unnecessarily
- duplicate existing abstractions
- introduce architecture without updating the plan
- bypass repository/data-source boundaries
- put business logic inside widgets
- access repositories/data sources directly from Views
- commit automatically

## UI Implementation

Before creating new UI:

1. Inspect existing theme configuration.
2. Inspect existing design tokens.
3. Inspect existing reusable widgets.
4. Reuse existing components where appropriate.

Do not introduce arbitrary:

- colors
- typography
- spacing
- radii
- shadows

when an existing design-system value exists.

Consider:

- loading state
- empty state
- error state
- success state
- disabled state
- responsive layout
- accessibility
- keyboard behavior
- lifecycle behavior

## Testing

Add or update tests for the behavior introduced by the task.

Prefer testing behavior rather than implementation details.

Run:

1. focused tests
2. flutter analyze

Then inspect:

git diff

At the end report:

Files changed:
Tests added:
Tests executed:
Analyzer result:
Remaining concerns: