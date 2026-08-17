---
description: Break an approved feature plan into small, independently verifiable implementation tasks.
---

You are decomposing an already-approved implementation plan into atomic engineering tasks.

Before doing anything:

1. Read AGENTS.md.
2. Read the relevant feature specification.
3. Read the relevant architecture plan.
4. Inspect the existing repository.
5. Do not modify application code.

## Task Requirements

Create or update:

specs/<feature>.tasks.md

Each task must:

- represent one logical change
- have a clear objective
- identify files likely to be created or modified
- identify the tests required
- have a clear completion condition
- be small enough to implement and review independently

Prefer tasks that can normally be completed in one focused implementation session.

## Task Structure

Use:

### TASK-001: <title>

**Objective**

What this task accomplishes.

**Changes**

- Files/components expected to change.

**Implementation Notes**

Important architectural constraints.

**Tests**

Tests that must be added or updated.

**Acceptance Criteria**

- [ ] Criterion 1
- [ ] Criterion 2

## Ordering

Order tasks according to dependencies.

Prefer:

1. Models/contracts
2. Persistence
3. Data sources
4. Repository
5. Business/data behavior
6. ViewModel
7. UI
8. Integration
9. E2E

Do not create tasks for unrelated refactoring.

Do not introduce architecture that is not required by the approved plan.

Do not implement anything.

At the end, report:

- number of tasks
- task dependency order
- any unresolved questions

Stop after producing the task document.