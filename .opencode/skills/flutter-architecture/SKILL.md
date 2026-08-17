---
name: flutter-architecture
description: Apply the project's MVVM architecture and dependency boundaries when designing or implementing Flutter features.
---

# Flutter Architecture

Use MVVM.

## Dependency direction

View
→ ViewModel
→ Repository
→ Data Sources

Never:

View → Repository
View → DataSource
ViewModel → DataSource
Background Service → ViewModel
DataSource → ViewModel

## View

Responsible for:

- rendering state
- user interaction
- navigation
- composition

Views must not contain business logic.

## ViewModel

Responsible for:

- UI state
- user actions
- coordinating repository operations
- translating domain/data results into UI state

ViewModels must not know about Drift implementation details.

## Repository

Responsible for:

- local persistence coordination
- remote communication coordination
- offline-first behavior
- synchronization boundaries

## Local Data Source

Responsible only for persistence.

## Remote Data Source

Responsible only for remote communication.

## Background Services

Background infrastructure must communicate with application/data infrastructure rather than presentation infrastructure.

## Rule

Prefer the simplest architecture that satisfies the requirement.

Do not introduce abstractions without a concrete architectural reason.