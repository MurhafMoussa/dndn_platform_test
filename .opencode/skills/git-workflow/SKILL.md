---
name: git-workflow
description: Conventional Commits and atomic Git workflow for the project.
---

# Git Workflow

Git history should communicate the engineering process clearly.

## Atomic Commits

A commit should contain one logical change.

Good:

feat(tracking): add location point model

test(tracking): add location point serialization tests

feat(database): add location persistence

Bad:

feat(tracking): build tracking feature, refactor architecture, update dependencies and tests

## Conventional Commits

Use:

feat:
fix:
test:
refactor:
perf:
docs:
chore:
build:
ci:

Optional scope:

feat(tracking):
feat(sync):
feat(incidents):
test(tracking):
fix(sync):

## Examples

feat(tracking): add location point model

test(tracking): add location point serialization tests

feat(database): persist tracking points locally

feat(sync): add tracking outbox

fix(sync): retry failed synchronization

test(sync): cover offline synchronization

feat(tracking): add tracking view model

feat(map): render recorded route

## Before Committing

Run:

git status
git diff

Then verify:

flutter analyze
flutter test

Check that:

- only intended files changed
- tests pass
- analyzer passes
- no secrets are included
- no unrelated refactoring is included

## Commit Approval

OpenCode must NOT commit automatically.

Before creating a commit:

1. Explain what the commit contains.
2. Propose a Conventional Commit message.
3. Show verification results.
4. Ask for explicit approval.

Never run:

git push

without explicit user approval.

Never use destructive commands such as:

git reset --hard
git clean -fd
git restore .
git checkout .

without explicit user approval.

## Generated Files

Do not manually commit generated files unless the project intentionally tracks them.

## Dependency Changes

Dependency changes should normally be isolated into their own commit when they are not part of the feature itself.

Example:

chore(deps): add drift persistence dependencies