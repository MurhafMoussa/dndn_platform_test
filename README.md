# Offline-First GPS Location Tracking & Telemetry Platform

A production-oriented, offline-first Flutter application demonstrating **MVVM architecture**, **dependency injection via GetIt**, **continuous background GPS location tracking with noise filtering**, **location permission guard & recovery**, **local SQLite persistence**, **outbox network synchronization**, **interactive Mapbox satellite mapping**, **hazard incident reporting**, and an **administrator telemetry dashboard**.

---

## Key Capabilities & Features

### 1. Continuous Background & Foreground GPS Tracking
* **Automatic GPS Sampling:** Captures position updates using a 2-second interval and 1-meter displacement filter threshold.
* **GPS Noise & Jitter Filtering (`LocationPointFilter`):** Drops urban GPS reflections, stationary drift (wander < 15m), and impossible coordinate spikes (> 200m) to keep path polyline rendering crisp and total distance calculation realistic.
* **Persistent Breadcrumb Route:** Persists coordinate snapshots locally to SQLite via Drift and calculates total geodesic path distance in real time.
* **Continuous Execution:** Tracking activates automatically on launch and stays active without manual pause/start friction.

### 2. Location Permission Guard & Auto-Recovery (`LocationPermissionGuard`)
* **App-Wide Permission Wrapper:** Enforces location permissions across the application with `LocationPermissionGuard` and `LocationPermissionErrorView`.
* **Background Permission Revocation Handling:** Monitors OS app lifecycle transitions (`WidgetsBindingObserver`). If location permission is revoked in background settings, the UI safely transitions to a permission error screen instead of crashing.
* **Automatic Tracking Recovery:** Automatically re-initializes `MapCubit` and resumes tracking as soon as permissions or GPS services are restored.

### 3. Service Locator Dependency Injection (`GetIt`)
* **Clean Architecture DI (`service_locator.dart`):** Centralized registration for SQLite database, repositories, services, and presentation Cubits via `GetIt`.
* **Testability:** Decoupled factory/singleton registration allows straightforward mock overrides in unit and widget test suites.

### 4. Interactive Mapbox Canvas (`MapView` & `MapCanvas`)
* **Live Route Polyline:** Renders the user's traveled route on a satellite-streets Mapbox style Uri.
* **Custom Profile Avatar Puck:** Dynamically downsamples and clips the user's personal photo into a crisp 80x80 circular avatar location puck with a white outer ring and drop shadow.
* **Vector Hazard Markers:** Uses `PointAnnotationManager` with cached high-DPI vector-style icons for reported hazards:
  * **Police**: Blue circular badge with police shield icon (`Icons.local_police_rounded`).
  * **Accident**: Red circular badge with vehicle collision icon (`Icons.car_crash_rounded`).
  * **Traffic Heavy**: Orange circular badge with traffic signal icon (`Icons.traffic_rounded`).
* **Camera Focus & Zoom Preservation:** Preserves custom camera zoom level across screen navigation (e.g. switching between Map and Admin dashboard) and animates fly-to target locations.

### 5. Native Splash Screen & Launcher Icons
* **Branded App Assets:** Customized high-resolution app launcher icon and native splash screen generated with `flutter_launcher_icons` and `flutter_native_splash`.
* **Android 12+ Splash API:** Full support for Android 12+ splash screens and dark mode themes.

### 6. Home Screen Widgets (`HomeWidgetService`)
* **Small Telemetry Widget (2x2):** Displays real-time total distance traveled (`1,250 m` / `3.4 km`) and live GPS status.
* **Large Telemetry Widget (4x3):** Offscreen canvas painter (`HomeWidgetMapSnapshot`) renders a real high-resolution satellite map snapshot image displaying the full traveled polyline route, green start dot, hazard markers, user circular avatar photo puck, and telemetry summary.

### 7. Offline-First Outbox Synchronization (`SyncEngine`)
* **Local-First Source of Truth:** All reads prefer locally persisted SQLite data.
* **Transactional Outbox Queue:** Mutations (`addLocationPoint`, `addIncidentReport`) are written atomically to local storage alongside a pending outbox record (`SyncOutboxItem`).
* **Resilient Sync Engine:** Processes outbox items through state transitions (`pending` $\rightarrow$ `syncing` $\rightarrow$ `synced` / `failed`). Idempotent retries ensure zero data loss during network outages.

### 8. Hazard Incident Reporting & Admin Dashboard (`AdminView`)
* **Location-Stamped Submission:** Users can report incidents (Police, Accident, Traffic Heavy) with immediate visual feedback via snackbars and local outbox persistence.
* **Telemetry Metrics:** Displays total distance traveled (formatted in meters/kilometers), total location points captured, and an itemized incident report log.
* **Role-Based Access Control:** Protected by `UserRoleCubit` and `AdminCubit`. Non-admin users see an `UnauthorizedView` with a quick "Switch to Administrator Mode" toggle.

---

## Architectural Principles & Design System

The application strictly follows **MVVM** and **Clean Architecture**:

```
Presentation (Views & ViewModels/Cubits)
       │
       ▼
Domain Layer (Models, Repository Contracts, Failures, LocationPointFilter)
       │
       ▼
Data Layer (Drift Database, Location Service, Sync Engine, Repositories)
```

* **SOLID Compliance:** High cohesion and single responsibility across all classes. ViewModels never depend on concrete UI/Mapbox SDK classes.
* **Widget Constraints:** Widgets are kept under 100–150 lines by breaking complex views into composable components (`MapFabGroup`, `MapCanvas`, `IncidentsTable`, `AdminTelemetryOverview`, `AdminTelemetryExplanationCard`, `LocationPermissionGuard`).
* **Functional Error Handling:** Uses `fpdart` (`Either`, `TaskEither`) for explicit, type-safe failure domain modeling (`TrackingFailure`).

---

## Directory Structure

```
lib/
├── core/
│   ├── constants/        # AppConstants & AppStrings
│   ├── di/               # Service Locator DI (GetIt setup)
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
│   └── utils/            # DistanceCalculator, LocationPointFilter
└── presentation/
    ├── cubits/           # MapCubit, AdminCubit, IncidentCubit, UserRoleCubit, LocationPermissionCubit
    ├── navigation/       # AppRouter (GoRouter declarative routes)
    ├── views/            # MapView, AdminView, UnauthorizedView
    └── widgets/          # LocationPermissionGuard, LocationPermissionErrorView, MapCanvas, MapFabGroup, etc.
```

---

## Getting Started

### Prerequisites
* **Flutter SDK:** `^3.22.1` or higher
* **Dart SDK:** `^3.12.1`
* **iOS:** Deployment target `14.0` or higher
* **Android:** `minSdk 21` or higher
* **Mapbox Account:** Free account at [account.mapbox.com](https://account.mapbox.com/) with Public Access Token (`pk.xxx`) and Secret Downloads Token (`sk.xxx`).

---

### Mapbox Token Guide & Configuration

#### 1. Creating Mapbox Tokens on Mapbox Dashboard

1. **Sign Up / Log In:**
   * Open [account.mapbox.com](https://account.mapbox.com/) and log in to your account.

2. **Get your Public Access Token (`pk.xxx`):**
   * On the **Access tokens** dashboard page, copy your **Default public token** (starts with `pk.eyJ...`).
   * This public key is used at runtime by Flutter to load map styles and satellite imagery.

3. **Generate a Secret Downloads Token (`sk.xxx`):**
   * Go to [account.mapbox.com/access-tokens/](https://account.mapbox.com/access-tokens/) and click **Create a token**.
   * Enter a name (e.g., `Flutter Android SDK Downloads`).
   * In the **Token scopes** section, check **`DOWNLOADS:READ`** (`Downloads:Read`).
   * Click **Create token**.
   * **Copy the secret token immediately** (starts with `sk.eyJ...`). *Note: Mapbox displays secret tokens only once!*

---

#### 2. Token Configuration Summary

| Token Type | Variable Name | Purpose | Where to Set |
| :--- | :--- | :--- | :--- |
| **Secret Downloads Token** (`sk.xxx`) | `MAPBOX_DOWNLOADS_TOKEN` | Enables Gradle to download native Mapbox Android SDK binaries during build. | Global user Gradle properties:<br>• **Windows:** `C:\Users\<username>\.gradle\gradle.properties`<br>• **macOS/Linux:** `~/.gradle/gradle.properties` |
| **Public Access Token** (`pk.xxx`) | `ACCESS_TOKEN` | Authorizes vector map tile rendering and satellite imagery at runtime. | App runtime configuration:<br>• `env.json` (`"ACCESS_TOKEN": "pk.xxx"`) or<br>• `--dart-define=ACCESS_TOKEN=pk.xxx` |

---

### Step-by-Step Configuration Guide

#### 1. Set Secret Downloads Token (`sk.xxx`) for Android Builds
To allow Gradle to fetch the native Mapbox Android SDK binary dependency, create or edit your global Gradle properties file:

* **Windows:** `C:\Users\<YourUsername>\.gradle\gradle.properties`
* **macOS / Linux:** `~/.gradle/gradle.properties`

Add your Secret Downloads Token:
```properties
MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_mapbox_downloads_token_here
```

> **Security Note:** Keeping secret tokens (`sk.xxx`) in your global user `~/.gradle/gradle.properties` ensures they are never committed to version control or flagged by GitHub Secret Scanning.

---

#### 2. Set Public Access Token (`pk.xxx`) for App Runtime
The application reads your Mapbox Public Access Token at launch to load map tiles.

1. **Copy the template file:**
   ```bash
   cp env.json.example env.json
   ```

2. **Add your Public Access Token to `env.json`:**
   ```json
   {
     "ACCESS_TOKEN": "pk.your_public_mapbox_access_token_here"
   }
   ```

---

### Execution Commands

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd dndn_platform_test
   ```

2. **Install Flutter dependencies:**
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

5. **Run automated unit & widget tests:**
   ```bash
   flutter test
   ```

6. **Launch application with `env.json`:**
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

   *Or pass token via command line:*
   ```bash
   flutter run --dart-define=ACCESS_TOKEN=pk.your_public_mapbox_access_token_here
   ```

---

## Testing Architecture

The codebase includes an extensive automated test suite (**103+ passing tests**) covering all layers:

* **Unit Tests:** Domain models, `DistanceCalculator`, `LocationPointFilter`, `LocationService`, `SyncEngine`, `HomeWidgetService`, `MapCubit`, `LocationPermissionCubit`, `AdminCubit`, `IncidentCubit`, `UserRoleCubit`.
* **Database Tests:** In-memory Drift SQLite CRUD, reactive table watchers, and outbox state transitions.
* **Widget Tests:** `LocationPermissionGuard`, `LocationPermissionErrorView`, `MapView`, `AdminView`, `UnauthorizedView`, `MapFabGroup`, `MyLocationButton`, `IncidentsTable`, `TelemetryCard`.
* **E2E Integration Test:** End-to-end workflow verifying tracking, incident reporting, outbox sync, and role access control (`test/integration/tracking_e2e_test.dart`).

---

## Conventional Commits

All changes follow **Conventional Commits**:

* `feat(...)`: New features, domain capabilities, and home screen widgets.
* `fix(...)`: Bug fixes and edge-case handling.
* `refactor(...)`: Architectural improvements and SOLID refactoring.
* `docs(...)`: Documentation and specifications.
* `test(...)`: Unit, widget, and integration test coverage.
