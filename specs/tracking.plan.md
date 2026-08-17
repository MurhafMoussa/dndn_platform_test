# Feature Architecture & Implementation Plan: Tracking & Incident Reporting

## 1. Architecture

The application follows a strict **MVVM (Model-View-ViewModel)** architecture paired with an **Offline-First Outbox Pattern** and **Functional Error Handling** via `fpdart`.

### Dependency Direction
Dependencies flow strictly inward:

```
View (MapView / AdminView)
  └── ViewModel / Cubit (MapCubit, IncidentCubit, AdminCubit, UserRoleCubit)
       └── Repository Contract (TrackingRepository using Either<TrackingFailure, T>)
            ├── Local Storage (Drift / SQLite Database)
            ├── Background Service (LocationService)
            └── Sync Engine (SyncEngine -> Console Dispatch)
```

* **Views:** Responsible strictly for UI rendering, user interactions, and listening to ViewModel state changes. Views never access repositories, databases, or API/network clients directly.
* **ViewModels / Cubits:** Manage UI state, process user input, coordinate repository calls, and expose presentation states using `Either` and `Option` from `fpdart`. ViewModels must not depend on UI widgets (`package:flutter/widgets.dart`), Drift database models, or network clients.
* **TrackingRepository:** The single coordination layer hiding database details and background sync triggers behind clean Dart interfaces returning `Either<TrackingFailure, T>`.
* **LocationService:** Manages periodic GPS capturing in background/foreground states and writes directly to `TrackingRepository`. Operates independently of UI lifecycle and ViewModels.
* **SyncEngine:** Handles offline-first outbox processing (`sync_outbox` table), executing simulated network dispatching when online.

---

## 2. Files to Create

### Domain Layer (Models, Failures & Repository Interfaces)
* `lib/domain/failures/tracking_failure.dart`: Specific strongly typed failure domain hierarchy (`TrackingFailure`).
* `lib/domain/models/location_point.dart`: Clean domain entity for recorded coordinates.
* `lib/domain/models/incident_report.dart`: Clean domain entity for reported incidents.
* `lib/domain/models/sync_outbox_item.dart`: Domain model for outbox queue payloads.
* `lib/domain/models/user_role.dart`: Enum defining `UserRole.user` and `UserRole.admin`.
* `lib/domain/repositories/tracking_repository.dart`: Repository interface contract utilizing `fpdart` return types (`Either<TrackingFailure, T>`).
* `lib/domain/utils/distance_calculator.dart`: Utility helper for distance calculation returning `Either<TrackingFailure, double>` using `Geolocator.distanceBetween`.

### Data Layer (Drift Database, Services & Repository Implementation)
* `lib/data/database/tables/location_points_table.dart`: Drift table definition for `location_points`.
* `lib/data/database/tables/incidents_table.dart`: Drift table definition for `incidents`.
* `lib/data/database/tables/sync_outbox_table.dart`: Drift table definition for `sync_outbox`.
* `lib/data/database/tracking_database.dart`: Primary Drift database class (`TrackingDatabase`).
* `lib/data/services/location_service.dart`: Periodic background GPS tracking service (2s sampling / 1m filter).
* `lib/data/sync/sync_engine.dart`: Outbox background processor for simulated network dispatch.
* `lib/data/repositories/tracking_repository_impl.dart`: Implementation of `TrackingRepository` catching exceptions and mapping them to `TrackingFailure`.

### Presentation Layer (Cubits, Views & Widgets)
* `lib/presentation/cubits/user_role_cubit.dart`: Cubit for user role state persisted via `HydratedBloc`.
* `lib/presentation/cubits/map/map_cubit.dart`: Cubit for location tracking, permissions, and map polyline state.
* `lib/presentation/cubits/map/map_state.dart`: Immutable state class for `MapCubit` using `Option<TrackingFailure>` for error handling.
* `lib/presentation/cubits/incident/incident_cubit.dart`: Cubit for incident form submission.
* `lib/presentation/cubits/incident/incident_state.dart`: Immutable state class for `IncidentCubit`.
* `lib/presentation/cubits/admin/admin_cubit.dart`: Cubit for loading telemetry metrics and guarding route access.
* `lib/presentation/cubits/admin/admin_state.dart`: Immutable state class for `AdminCubit`.
* `lib/presentation/views/map_view.dart`: Primary interactive Mapbox map view screen.
* `lib/presentation/views/admin_view.dart`: Protected admin telemetry dashboard view screen.
* `lib/presentation/views/unauthorized_view.dart`: View displayed when a non-admin session accesses `/admin`.
* `lib/presentation/widgets/incident_report_dialog.dart`: Incident selection dialog (Police, Accident, Traffic Heavy).
* `lib/presentation/widgets/app_navigation_drawer.dart`: Navigation drawer for view switching and role toggling.
* `lib/presentation/widgets/telemetry_card.dart`: Summary metric card widget for Admin Dashboard.
* `lib/presentation/widgets/incidents_table.dart`: Data table widget for displaying itemized incident logs.

### Test Files
* `test/domain/distance_calculator_test.dart`: Unit tests for total distance calculation.
* `test/data/database/tracking_database_test.dart`: In-memory Drift database integration tests.
* `test/data/repositories/tracking_repository_test.dart`: Repository unit tests for atomic writes & outbox enqueueing with `fpdart` assertions.
* `test/data/sync/sync_engine_test.dart`: Sync engine outbox processing tests.
* `test/presentation/cubits/user_role_cubit_test.dart`: `HydratedBloc` role persistence tests.
* `test/presentation/cubits/map_cubit_test.dart`: MapCubit state transition unit tests.
* `test/presentation/cubits/admin_cubit_test.dart`: AdminCubit telemetry & route guard tests.
* `test/presentation/views/map_view_test.dart`: Widget tests for map view and incident FAB.
* `test/presentation/views/admin_view_test.dart`: Widget tests for Admin Dashboard and unauthorized state.

---

## 3. Files to Modify

* `pubspec.yaml`:
  * Add dependencies: `fpdart`, `flutter_bloc`, `hydrated_bloc`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `geolocator`, `mapbox_maps_flutter`, `uuid`, `equatable`.
  * Add dev_dependencies: `build_runner`, `drift_dev`, `hydrated_bloc` testing utilities.
* `lib/main.dart`:
  * Replace counter demo app with application entry point initializing `HydratedStorage`, `TrackingDatabase`, `TrackingRepository`, `SyncEngine`, and top-level `MultiBlocProvider`.

---

## 4. Data Model & Failure Hierarchy

### Domain Failure Hierarchy (`lib/domain/failures/tracking_failure.dart`)

```dart
import 'package:equatable/equatable.dart';

abstract class TrackingFailure extends Equatable {
  final String message;
  final dynamic cause;

  const TrackingFailure(this.message, [this.cause]);

  @override
  List<Object?> get props => [message, cause];
}

/// Thrown when foreground or background location permission is denied by the user.
class LocationPermissionDeniedFailure extends TrackingFailure {
  final bool isPermanentlyDenied;

  const LocationPermissionDeniedFailure({
    required String message,
    this.isPermanentlyDenied = false,
    dynamic cause,
  }) : super(message, cause);

  @override
  List<Object?> get props => [message, isPermanentlyDenied, cause];
}

/// Thrown when GPS location services are disabled on the user's device.
class LocationServiceDisabledFailure extends TrackingFailure {
  const LocationServiceDisabledFailure([
    String message = 'GPS location services are disabled on device.',
  ]) : super(message);
}

/// Thrown when a Drift / SQLite read, write, or transaction fails.
class DatabaseFailure extends TrackingFailure {
  const DatabaseFailure(String message, [dynamic cause]) : super(message, cause);
}

/// Thrown when sync outbox payload processing fails.
class SyncFailure extends TrackingFailure {
  const SyncFailure(String message, [dynamic cause]) : super(message, cause);
}

/// Thrown when a non-admin session attempts to access restricted telemetry data.
class UnauthorizedAccessFailure extends TrackingFailure {
  const UnauthorizedAccessFailure([
    String message = 'Access restricted to administrator sessions only.',
  ]) : super(message);
}

/// Thrown when distance calculation fails due to insufficient or invalid coordinates.
class DistanceCalculationFailure extends TrackingFailure {
  const DistanceCalculationFailure(String message, [dynamic cause]) : super(message, cause);
}
```

### Domain Entities

```dart
enum UserRole { user, admin }

enum IncidentType { police, accident, trafficHeavy }

enum SyncStatus { pending, syncing, synced, failed }

class LocationPoint extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const LocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, latitude, longitude, timestamp];
}

class IncidentReport extends Equatable {
  final String id;
  final IncidentType type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const IncidentReport({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, type, latitude, longitude, timestamp];
}

class SyncOutboxItem extends Equatable {
  final String id;
  final String eventType;
  final String payload; // JSON serialized string
  final DateTime createdAt;
  final SyncStatus status;

  const SyncOutboxItem({
    required this.id,
    required this.eventType,
    required this.payload,
    required this.createdAt,
    required this.status,
  });

  @override
  List<Object?> get props => [id, eventType, payload, createdAt, status];
}
```

---

## 5. Repository API (using `fpdart`)

```dart
import 'package:fpdart/fpdart.dart';
import 'package:dndn_platform_test/domain/failures/tracking_failure.dart';
import 'package:dndn_platform_test/domain/models/location_point.dart';
import 'package:dndn_platform_test/domain/models/incident_report.dart';
import 'package:dndn_platform_test/domain/models/sync_outbox_item.dart';

abstract class TrackingRepository {
  /// Stream of chronologically ordered location points wrapped in Either
  Stream<Either<TrackingFailure, List<LocationPoint>>> watchLocationPoints();

  /// Stream of incident reports wrapped in Either
  Stream<Either<TrackingFailure, List<IncidentReport>>> watchIncidents();

  /// Stream of pending outbox items wrapped in Either
  Stream<Either<TrackingFailure, List<SyncOutboxItem>>> watchPendingOutbox();

  /// Atomic operation: Persist location point locally and enqueue sync_outbox item
  Future<Either<TrackingFailure, Unit>> addLocationPoint(LocationPoint point);

  /// Atomic operation: Persist incident report locally and enqueue sync_outbox item
  Future<Either<TrackingFailure, Unit>> addIncidentReport(IncidentReport incident);

  /// Computes total distance traveled in meters across all recorded points using fpdart TaskEither
  TaskEither<TrackingFailure, double> getTotalDistanceMeters();

  /// Processes pending outbox items and updates outbox state
  Future<Either<TrackingFailure, Unit>> flushOutbox();
}
```

---

## 6. ViewModel API

### UserRoleCubit
```dart
class UserRoleCubit extends HydratedCubit<UserRole> {
  UserRoleCubit() : super(UserRole.user);

  void setRole(UserRole role);
  void toggleRole();

  @override
  UserRole? fromJson(Map<String, dynamic> json);

  @override
  Map<String, dynamic>? toJson(UserRole state);
}
```

### MapCubit
```dart
class MapCubit extends Cubit<MapState> {
  final TrackingRepository repository;
  final LocationService locationService;

  MapCubit({required this.repository, required this.locationService})
      : super(MapState.initial());

  Future<void> initializeMap();
  Future<void> startTracking();
  Future<void> stopTracking();
  void handlePermissionFailure(LocationPermissionDeniedFailure failure);
}
```

### IncidentCubit
```dart
class IncidentCubit extends Cubit<IncidentState> {
  final TrackingRepository repository;

  IncidentCubit({required this.repository})
      : super(IncidentState.initial());

  Future<Either<TrackingFailure, Unit>> submitIncident({
    required IncidentType type,
    required double latitude,
    required double longitude,
  });
}
```

### AdminCubit
```dart
class AdminCubit extends Cubit<AdminState> {
  final TrackingRepository repository;

  AdminCubit({required this.repository})
      : super(AdminState.initial());

  Future<void> loadTelemetry(UserRole activeRole);
}
```

---

## 7. Presentation Architecture

```
                               ┌──────────────────────┐
                               │     MaterialApp      │
                               └──────────┬───────────┘
                                          │
                        ┌─────────────────┴─────────────────┐
                        │        MultiBlocProvider          │
                        │ - UserRoleCubit (HydratedBloc)    │
                        │ - MapCubit                        │
                        │ - IncidentCubit                   │
                        │ - AdminCubit                      │
                        └─────────────────┬─────────────────┘
                                          │
                        ┌─────────────────┴─────────────────┐
                        │          AppNavigation            │
                        └──────────┬──────────────┬─────────┘
                                   │              │
                   ┌───────────────┴──┐        ┌──┴───────────────┐
                   │     MapView      │        │    AdminView     │
                   │ (Mapbox, FAB)    │        │ (Telemetry Cards,│
                   └──────────────────┘        │  Incidents Table)│
                                               └──────────────────┘
```

* **Route Guarding:** When navigating to `/admin`, `AdminView` verifies `UserRoleCubit.state`. If state is `UserRole.user`, `AdminView` renders `UnauthorizedView` corresponding to `UnauthorizedAccessFailure`.
* **Navigation Drawer:** `AppNavigationDrawer` provides direct access to Map View (`/`), Admin Dashboard (`/admin`), and a role switcher toggle switch.

---

## 8. UI States & Specific Failure Mapping

### Map View States (`MapState`)
* **`MapInitial`:** Initializing Mapbox canvas and checking location permissions.
* **`MapLoading`:** Loading recorded location points and polyline history from local storage.
* **`MapLoaded`:** Active map rendering current location marker, polyline route overlay, and FAB.
* **`MapFailure`:** Emitted when location tracking or map initialization fails, carrying an `Option<TrackingFailure>`:
  * `LocationPermissionDeniedFailure`: Shows non-intrusive banner indicating location permission is denied.
  * `LocationServiceDisabledFailure`: Prompts user to enable GPS location service in device settings.
  * `DatabaseFailure`: Displays local storage failure snackbar/banner.

### Incident Form States (`IncidentState`)
* **`IncidentInitial`:** Form dialog ready for user interaction.
* **`IncidentSubmitting`:** Writing incident record and outbox item locally.
* **`IncidentSuccess`:** Submission successful; triggers SnackBar feedback and closes dialog.
* **`IncidentFailure`:** Carries a `DatabaseFailure` or `SyncFailure`, displaying error text inside the dialog.

### Admin Dashboard States (`AdminState`)
* **`AdminLoading`:** Computing total distance and querying incidents table from local Drift DB.
* **`AdminLoaded`:** Displaying summary cards (Total Distance in meters, Total Points count) and Incident log table.
* **`AdminUnauthorized`:** Emitted when `UnauthorizedAccessFailure` is triggered because active role is `UserRole.user`.

---

## 9. Reusable Components

* `AppNavigationDrawer`: Drawer containing navigation items and user role state switcher.
* `TelemetryCard`: Metric display widget showing icon, metric title, and value string (e.g. "1,250 m").
* `IncidentsTable`: Paginated/scrollable Data Table listing incident logs with columns for Type, Timestamp, Latitude, and Longitude.
* `IncidentReportDialog`: Modal dialog displaying 3 choices (Police, Accident, Traffic Heavy) with distinctive icons and titles.

---

## 10. Responsive Behavior

* **Mobile Form Factor:**
  * Map screen uses full viewport height with Floating Action Button at bottom-right.
  * Admin Dashboard displays metric cards stacked vertically in a single column.
* **Tablet / Wide Displays:**
  * Admin Dashboard displays metric cards side-by-side using a responsive `Row` or `GridView`.
  * Incident table expands horizontally to utilize available screen width without horizontal overflow.

---

## 11. Accessibility Considerations

* **Semantic Labels:** Add explicit `Semantics` tags to the Floating Action Button, Mapbox markers, Navigation Drawer choices, and Incident selection options.
* **Touch Targets:** All interactive buttons (FAB, Incident choices, Drawer items) maintain a minimum touch target size of 48x48 dp.
* **Contrast & Color:** Ensure high-contrast color choices for polyline route lines, status indicators, and text tokens adhering to ThemeData contrast guidelines.

---

## 12. Offline-First Flow

```
[User Action / GPS Capture]
          │
          ▼
[1. Local Database Write (Drift)]
  - Insert row in `location_points` OR `incidents`
  - Enqueue row in `sync_outbox` (status: 'pending')
  (Executes inside a single atomic SQLite transaction; returns Either<DatabaseFailure, Unit>)
          │
          ▼
[2. Reactive UI Update]
  - Drift reactive stream emits updated dataset (Stream<Either<TrackingFailure, List<T>>>)
  - ViewModels update state; Map & Admin UI re-render instantly
          │
          ▼
[3. Sync Engine Outbox Execution]
  - Network monitor detects connectivity
  - Pending outbox items processed sequentially
  - Dispatched payload printed to console (simulated dispatch)
  - Outbox status updated from 'pending' -> 'synced' (or 'failed' on SyncFailure)
```

---

## 13. Sync Behavior

* **`SyncEngine` Processing:**
  1. Queries `sync_outbox` for items where `status = 'pending'` ordered by `created_at` ASC.
  2. Updates item status to `'syncing'`.
  3. Simulates network transmission (1s delay) and prints JSON payload to console.
  4. On success: updates item status to `'synced'` / deletes processed outbox entry.
  5. On failure: catches error, yields `SyncFailure`, and updates item status to `'failed'`, preserving local database records intact.
* **Idempotency:** Re-processing a failed outbox item does not duplicate local `location_points` or `incidents` records.

---

## 14. Testing Strategy

* **Unit Tests (`fpdart` Matchers):**
  * `TrackingRepositoryImpl`: verify atomic writes return `Right(unit)` and database errors return `Left(DatabaseFailure)`.
  * `DistanceCalculator`: test `Geolocator.distanceBetween` returning `Right(distance)` or `Left(DistanceCalculationFailure)`.
  * `UserRoleCubit`: verify role state updates and `HydratedBloc` persistence.
  * `MapCubit` / `AdminCubit`: verify state transitions on `Left(LocationPermissionDeniedFailure)` or `Left(UnauthorizedAccessFailure)`.
  * `SyncEngine`: verify outbox processing and `SyncFailure` handling.
* **Widget Tests:**
  * `MapView`: test map canvas rendering, FAB tap, and dialog trigger.
  * `IncidentReportDialog`: test options rendering and submission callback.
  * `AdminView`: verify summary cards, incident table rendering, and `UnauthorizedView` fallback when role is `UserRole.user`.
* **Integration Tests:**
  * In-memory `TrackingDatabase` testing schema creation, reactive stream updates, and transactions.

---

## 15. Failure & Exception Mapping Matrix

| Failure Type | Trigger Condition | Handled By / UI Output |
| --- | --- | --- |
| `LocationPermissionDeniedFailure` | Location permission denied by user (foreground or background). | `MapCubit` emits `MapFailure`; UI shows non-intrusive warning banner. |
| `LocationServiceDisabledFailure` | Device GPS services turned off. | `MapCubit` emits `MapFailure`; UI prompts user to enable location services. |
| `DatabaseFailure` | Drift / SQLite database read/write/transaction error. | Repository returns `Left(DatabaseFailure)`; Cubit displays error SnackBar. |
| `SyncFailure` | Outbox payload serialization or dispatch error. | `SyncEngine` marks outbox entry status as `failed`; local data preserved. |
| `UnauthorizedAccessFailure` | Non-admin session accesses `/admin`. | `AdminCubit` emits `AdminUnauthorized`; UI renders `UnauthorizedView`. |
| `DistanceCalculationFailure` | Less than 2 location points or invalid lat/long values. | `DistanceCalculator` returns `Right(0.0)` or `Left(DistanceCalculationFailure)`. |

---

## 16. Risks

* **Location Permission Policies:** iOS and Android require background location usage descriptions in Info.plist / AndroidManifest.xml.
  * *Mitigation:* Ensure permission keys are declared and handled gracefully via `LocationPermissionDeniedFailure`.
* **Mapbox Public Token Configuration:** Missing `--dart-define=MAPBOX_ACCESS_TOKEN` during testing.
  * *Mitigation:* Provide a developer fallback token or mock map container for widget tests.

---

## 17. Migration Considerations

* **Database Version:** Initial Drift database schema version is set to `1`.
* **Application Bootstrapping:** Replace default `main.dart` counter implementation with application setup initializing `HydratedStorage`, database singletons, repositories, and BLoC providers.
