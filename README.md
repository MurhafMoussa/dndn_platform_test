# Offline-First GPS Location Tracking & Telemetry Platform

A production-oriented, offline-first Flutter application demonstrating **MVVM architecture**, **continuous background GPS location tracking**, **local SQLite persistence**, **outbox network synchronization**, **interactive Mapbox satellite mapping**, **hazard incident reporting**, and an **administrator telemetry dashboard**.

---

## Key Capabilities & Features

### 1. Continuous Background & Foreground GPS Tracking
* **Automatic GPS Sampling:** Captures position updates using a 2-second interval and 1-meter displacement filter threshold.
* **Persistent Breadcrumb Route:** Persists every coordinate snapshot locally to SQLite via Drift and calculates total geodesic path distance in real time.
* **Continuous Execution:** Tracking activates automatically on launch and stays active without manual pause/start friction.

### 2. Interactive Mapbox Canvas (`MapView` & `MapCanvas`)
* **Live Route Polyline:** Renders the user's traveled route on a satellite-streets Mapbox style Uri.
* **Custom Profile Avatar Puck:** Dynamically downsamples and clips the user's personal photo into a crisp 80x80 circular avatar location puck with a white outer ring and drop shadow.
* **Vector Hazard Markers:** Uses `PointAnnotationManager` with cached high-DPI vector-style icons for reported hazards:
  * **Police**: Blue circular badge with police shield icon (`Icons.local_police_rounded`).
  * **Accident**: Red circular badge with vehicle collision icon (`Icons.car_crash_rounded`).
  * **Traffic Heavy**: Orange circular badge with traffic signal icon (`Icons.traffic_rounded`).
* **Camera Focus & Zoom Preservation:** Preserves custom camera zoom level across screen navigation (e.g. switching between Map and Admin dashboard) and animates fly-to target locations.

### 3. Home Screen Widgets (`HomeWidgetService`)
* **Small Telemetry Widget (2x2):** Displays real-time total distance traveled (`1,250 m` / `3.4 km`) and live GPS status.
* **Large Telemetry Widget (4x3):** Offscreen canvas painter (`HomeWidgetMapSnapshot`) renders a real high-resolution satellite map snapshot image displaying the full traveled polyline route, green start dot, hazard markers, user circular avatar photo puck, and telemetry summary.

### 4. Offline-First Outbox Synchronization (`SyncEngine`)
* **Local-First Source of Truth:** All reads prefer locally persisted SQLite data.
* **Transactional Outbox Queue:** Mutations (`addLocationPoint`, `addIncidentReport`) are written atomically to local storage alongside a pending outbox record (`SyncOutboxItem`).
* **Resilient Sync Engine:** Processes outbox items through state transitions (`pending` $\rightarrow$ `syncing` $\rightarrow$ `synced` / `failed`). Idempotent retries ensure zero data loss during network outages.

### 5. Hazard Incident Reporting
* **Location-Stamped Submission:** Users can report incidents (Police, Accident, Traffic Heavy) with immediate visual feedback via snackbars and local outbox persistence.

### 6. Administrator Telemetry Dashboard (`AdminView`)
* **Telemetry Metrics:** Displays total distance traveled (formatted in meters/kilometers), total location points captured, and an itemized incident report log.
* **Role-Based Access Control:** Protected by `UserRoleCubit` and `AdminCubit`. Non-admin users see an `UnauthorizedView` with a quick "Switch to Administrator Mode" toggle that seamlessly reloads telemetry without double navigation bars.

---

## Architectural Principles & Design System

The application strictly follows **MVVM** and **Clean Architecture**:

```
Presentation (Views & ViewModels/Cubits)
       │
       ▼
Domain Layer (Models, Repository Contracts, Failures)
       │
       ▼
Data Layer (Drift Database, Location Service, Sync Engine, Repositories)
```

* **SOLID Compliance:** High cohesion and single responsibility across all classes. ViewModels never depend on concrete UI/Mapbox SDK classes.
* **Widget Constraints:** Widgets are kept under 100–150 lines by breaking complex views into composable components (`MapFabGroup`, `MapCanvas`, `IncidentsTable`, `AdminTelemetryOverview`, `AdminTelemetryExplanationCard`).
* **Functional Error Handling:** Uses `fpdart` (`Either`, `TaskEither`) for explicit, type-safe failure domain modeling (`TrackingFailure`).

---

## Directory Structure

```
lib/
├── core/
│   ├── constants/        # AppConstants & AppStrings
│   └── theme/            # AppSpacing & Design Tokens
├── data/
│   ├── database/         # Drift SQLite Database & Tables (LocationPoints, Incidents, SyncOutbox)
│   ├── repositories/     # TrackingRepositoryImpl (Atomic writes & outbox queue)
│   ├── services/         # LocationService, HomeWidgetService
│   └── sync/             # SyncEngine (Outbox flush processor)
├── domain/
│   ├── failures/         # Strongly-typed TrackingFailure domain hierarchy
│   ├── models/           # Domain models (LocationPoint, IncidentReport, UserRole, SyncOutboxItem)
│   ├── repositories/     # TrackingRepository interface contract
│   └── services/         # DistanceCalculator (Haversine geodesic distance)
└── presentation/
    ├── cubits/           # MapCubit, AdminCubit, IncidentCubit, UserRoleCubit & States
    ├── navigation/       # AppRouter (GoRouter declarative routes)
    ├── views/            # MapView, AdminView, UnauthorizedView
    └── widgets/          # MapCanvas, MapFabGroup, HomeWidgetMapSnapshot, IncidentIconHelper, IncidentsTable, etc.
```

---

## Getting Started

### Prerequisites
* **Flutter SDK:** `^3.22.1` or higher
* **Dart SDK:** `^3.12.1`
* **iOS:** Deployment target `14.0` or higher
* **Android:** `minSdk 21` or higher
* **Mapbox Account:** Free account with Mapbox Public Access Token (`pk.xxx`) and Secret Downloads Token (`sk.xxx`).

---

### Configuration & Setup

#### 1. Mapbox Downloads Token (Android Build Setup)
The Mapbox Maps SDK for Android requires a Secret Downloads Token (`sk.xxx`) to download the native SDK binaries via Gradle.

Create or update your local Gradle properties file at `~/.gradle/gradle.properties` (or set `MAPBOX_DOWNLOADS_TOKEN` in `android/gradle.properties` locally):

```properties
MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_mapbox_downloads_token_here
```

> **Note:** Never commit secret tokens (`sk.xxx`) to version control. The repository's `android/gradle.properties` uses placeholder variables by default.

---

#### 2. Environment Configuration (`env.json`)
The application uses `env.json` to pass runtime environment variables (such as your Mapbox Public Access Token `pk.xxx`) into Flutter.

1. **Copy the example configuration:**
   ```bash
   cp env.json.example env.json
   ```

2. **Add your Mapbox Public Access Token to `env.json`:**
   ```json
   {
     "ACCESS_TOKEN": "pk.your_public_mapbox_access_token_here"
   }
   ```

---

### Installation & Execution Commands

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd dndn_platform_test
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Drift database bindings (if modifying database models):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run static analysis:**
   ```bash
   flutter analyze
   ```

5. **Run the automated test suite:**
   ```bash
   flutter test
   ```

6. **Run the application with `env.json`:**
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

   *Alternatively, pass the token directly via CLI:*
   ```bash
   flutter run --dart-define=ACCESS_TOKEN=pk.your_public_mapbox_access_token_here
   ```

---

## Testing Architecture

The codebase includes an extensive automated test suite (**91 passing tests**) covering all layers:

* **Unit Tests:** Models, `DistanceCalculator`, `LocationService`, `SyncEngine`, `HomeWidgetService`, `MapCubit`, `AdminCubit`, `IncidentCubit`, `UserRoleCubit`.
* **Database Tests:** In-memory Drift SQLite CRUD, reactive table watchers, and outbox state transitions.
* **Widget Tests:** `MapView`, `AdminView`, `UnauthorizedView`, `MapFabGroup`, `MyLocationButton`, `IncidentsTable`, `TelemetryCard`.
* **E2E Integration Test:** End-to-end workflow verifying tracking, incident reporting, outbox sync, and role access control (`test/integration/tracking_e2e_test.dart`).

---

## Conventional Commits

All changes follow **Conventional Commits**:

* `feat(...)`: New features, domain capabilities, and home screen widgets.
* `fix(...)`: Bug fixes and edge-case handling.
* `refactor(...)`: Architectural improvements and SOLID refactoring.
* `docs(...)`: Documentation and specifications.
* `test(...)`: Unit, widget, and integration test coverage.
