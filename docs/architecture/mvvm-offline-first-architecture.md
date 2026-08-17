

## Architecture Overview
This application strictly follows **MVVM (Model-View-ViewModel)** with an **Offline-First Outbox Pattern**.


```

┌─────────────────────────────────────────────────────────────────┐
│                       PRESENTATION LAYER                        │
│  ┌─────────────────────────────┐   ┌─────────────────────────┐  │
│  │ View (MapScreen/AdminView)  │ <─>│ ViewModel / Cubit       │  │
│  └─────────────────────────────┘   └─────────────────────────┘  │
└─────────────────────────────────────────┬───────────────────────┘
│ Calls
┌─────────────────────────────────────────▼───────────────────────┐
│                           DATA LAYER                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    TrackingRepository                     │  │
│  └──────────────┬───────────────────────────┬────────────────┘  │
│                 │ Write / Read              │ Flush Sync        │
│                 ▼                           ▼                   │
│  ┌─────────────────────────────┐   ┌─────────────────────────┐  │
│  │  Drift Local Storage (DB)   │   │       SyncEngine        │  │
│  │  - location_points          │   └────────────┬────────────┘  │
│  │  - incidents                │                │               │
│  │  - sync_outbox              │                ▼               │
│  └─────────────────────────────┘   ┌─────────────────────────┐  │
│                                    │  Remote API / Mock WS   │  │
│                                    └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

```

---

## Data Layer & Persistence Rules

1. **Single Source of Truth:** Drift (SQLite) is the authoritative source of truth.
2. **Read Strategy:** ViewModels observe reactive streams exposed by `TrackingRepository` which listen directly to Drift tables. UI components never poll network APIs directly.
3. **Write Strategy (Outbox Pattern):**
   * All mutations (new location coordinates, incident submissions) are written to local Drift tables in a single transaction.
   * A corresponding pending payload is appended to the `sync_outbox` table.
   * `SyncEngine` processes pending `sync_outbox` entries asynchronously when network connectivity is available.
4. **Data Isolation:** Domain entities and Drift persistence objects are kept separate from UI widgets. HydratedBloc is strictly disallowed for persistent business domain records.

---

## Component Boundaries

* **Views:** Handle rendering state, user input events, map canvas interactions, and dialog presentation.
  * *Constraint:* NO direct calls to repositories, data sources, or database classes.
* **ViewModels / Cubits:** Manage UI state, process view interactions, call repository methods, and map repository results into presentation states.
  * *Constraint:* NO imports of `package:flutter/widgets.dart`, `package:drift/`, or HTTP clients (`Dio`).
* **TrackingRepository:** Coordinates local database storage (`TrackingDatabase`) and background sync triggers. Exposes clean Dart streams and models to ViewModels.
  * *Constraint:* Hides database generated classes and network implementation details behind clean Dart interface contracts.
* **Background Location Service:** Operates independently of presentation lifecycle. Captures GPS points and writes directly to `TrackingRepository`.
  * *Constraint:* NO references to UI components, BuildContext, or ViewModels.

---

## Drift Database Schemas

```sql
-- Location Points
CREATE TABLE location_points (
    id TEXT PRIMARY KEY NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    timestamp INTEGER NOT NULL
);

-- Incident Reports
CREATE TABLE incidents (
    id TEXT PRIMARY KEY NOT NULL,
    type TEXT NOT NULL, -- 'Police', 'Accident', 'Traffic Heavy'
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    timestamp INTEGER NOT NULL
);

-- Sync Outbox Queue
CREATE TABLE sync_outbox (
    id TEXT PRIMARY KEY NOT NULL,
    event_type TEXT NOT NULL,
    payload TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    status TEXT NOT NULL -- 'pending', 'syncing', 'failed'
);

