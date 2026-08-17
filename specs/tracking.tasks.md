# Engineering Tasks: Tracking & Incident Reporting Feature

---

### TASK-001: Configure Project Dependencies & Setup Environment

**Objective**
Add required packages (`fpdart`, `flutter_bloc`, `hydrated_bloc`, `drift`, `sqlite3_flutter_libs`, `geolocator`, `mapbox_maps_flutter`, `path_provider`, `path`, `uuid`, `equatable`, `build_runner`, `drift_dev`) to `pubspec.yaml` and verify build setup.

**Changes**
- `pubspec.yaml`

**Implementation Notes**
- Strictly specify compatible package versions adhering to Dart SDK constraint `^3.12.1`.
- Do not introduce dependencies not authorized by the implementation plan.

**Tests**
- Execute `flutter pub get` to verify resolution.

**Acceptance Criteria**
- [ ] Dependencies are cleanly resolved without pub version conflicts.
- [ ] `flutter analyze` runs clean without error warnings.

---

### TASK-002: Define Domain Models & Failure Hierarchy

**Objective**
Create domain entities (`LocationPoint`, `IncidentReport`, `SyncOutboxItem`, `UserRole`) and strongly typed failure hierarchy (`TrackingFailure`, `LocationPermissionDeniedFailure`, `LocationServiceDisabledFailure`, `DatabaseFailure`, `SyncFailure`, `UnauthorizedAccessFailure`, `DistanceCalculationFailure`).

**Changes**
- `lib/domain/failures/tracking_failure.dart`
- `lib/domain/models/location_point.dart`
- `lib/domain/models/incident_report.dart`
- `lib/domain/models/sync_outbox_item.dart`
- `lib/domain/models/user_role.dart`

**Implementation Notes**
- Inherit domain entities and failures from `Equatable`.
- Ensure domain models do not import Flutter UI widgets or Drift database models.

**Tests**
- `test/domain/models_test.dart`: Test equality props, failure properties, and instantiation.

**Acceptance Criteria**
- [ ] All 7 failure classes in the domain hierarchy are defined cleanly.
- [ ] Entities support value comparison via `props`.
- [ ] Unit tests pass 100%.

---

### TASK-003: Define Repository Interface Contract

**Objective**
Define the `TrackingRepository` abstract interface contract using `fpdart` return types (`Stream<Either<TrackingFailure, List<T>>>`, `Future<Either<TrackingFailure, Unit>>`, `TaskEither<TrackingFailure, double>`).

**Changes**
- `lib/domain/repositories/tracking_repository.dart`

**Implementation Notes**
- Method signatures must strictly return `Either` or `TaskEither` types.
- Hide infrastructure and database concrete classes behind clean Dart contracts.

**Tests**
- Compilation check for imports and contract signature consistency.

**Acceptance Criteria**
- [ ] Interface contract is defined with no concrete database imports.
- [ ] All methods utilize `Either` or `TaskEither` from `fpdart`.

---

### TASK-004: Create Drift Relational Database Tables & Database Instance

**Objective**
Define Drift tables (`location_points`, `incidents`, `sync_outbox`) and implement `TrackingDatabase` with reactive table watchers and CRUD operations.

**Changes**
- `lib/data/database/tables/location_points_table.dart`
- `lib/data/database/tables/incidents_table.dart`
- `lib/data/database/tables/sync_outbox_table.dart`
- `lib/data/database/tracking_database.dart`

**Implementation Notes**
- Use SQLite column types (`TextColumn`, `RealColumn`, `IntColumn`).
- Run `build_runner` to generate `tracking_database.g.dart`.
- Provide reactive watchers returning `Stream<List<DataClass>>`.

**Tests**
- `test/data/database/tracking_database_test.dart`: In-memory Drift database CRUD and reactive table stream tests.

**Acceptance Criteria**
- [ ] Drift schema version set to `1`.
- [ ] Generated Drift file builds cleanly via `build_runner`.
- [ ] In-memory database integration tests pass 100%.

---

### TASK-005: Implement Background Location Service

**Objective**
Implement `LocationService` to manage periodic background/foreground GPS tracking with 2-second interval sampling and 1-meter displacement filter threshold, handling location streams and permission check failures cleanly.

**Changes**
- `lib/data/services/location_service.dart`

**Implementation Notes**
- Utilize `Geolocator` stream settings with `LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 1, timeLimit: Duration(seconds: 2))`.
- Catch permission errors and yield `LocationPermissionDeniedFailure` or `LocationServiceDisabledFailure`.
- Service must operate independently without depending on Views or ViewModels.

**Tests**
- `test/data/services/location_service_test.dart`: Mock geolocator location stream and test permission error mapping.

**Acceptance Criteria**
- [ ] Periodic GPS capture runs at 2s / 1m filter settings.
- [ ] Permission denials are mapped to `LocationPermissionDeniedFailure`.
- [ ] Unit tests pass 100%.

---

### TASK-006: Implement Outbox Sync Engine

**Objective**
Implement `SyncEngine` for background outbox processing, reading pending entries from `sync_outbox`, transitioning status from `pending` -> `syncing` -> `synced`, and printing JSON payloads to the console to simulate real-time WebSocket emissions.

**Changes**
- `lib/data/sync/sync_engine.dart`

**Implementation Notes**
- Process outbox entries ordered by `created_at` ASC.
- Catch processing exceptions and mark item status as `failed` with `SyncFailure` without deleting local data.

**Tests**
- `test/data/sync/sync_engine_test.dart`: Test outbox processing, status transitions, and console output simulation.

**Acceptance Criteria**
- [ ] Pending outbox items transition status cleanly (`pending` -> `syncing` -> `synced`).
- [ ] Outgoing JSON dispatch is printed to console.
- [ ] Failed attempts retain local database entries intact.

---

### TASK-007: Implement Tracking Repository

**Objective**
Implement `TrackingRepositoryImpl` coordinating Drift database storage and `SyncEngine`, executing atomic local writes and `sync_outbox` enqueues inside single database transactions, returning `Either<TrackingFailure, T>`.

**Changes**
- `lib/data/repositories/tracking_repository_impl.dart`

**Implementation Notes**
- Wrap Drift queries and mutations in `try-catch` blocks mapping exceptions to `DatabaseFailure`.
- Convert Drift generated `DataClass` objects to domain entities (`LocationPoint`, `IncidentReport`).

**Tests**
- `test/data/repositories/tracking_repository_test.dart`: Test atomic `addLocationPoint`, `addIncidentReport`, and stream conversion returning `Either`.

**Acceptance Criteria**
- [ ] Local writes and outbox enqueues execute atomically in single transactions.
- [ ] Database errors return `Left(DatabaseFailure)`.
- [ ] Unit tests pass 100%.

---

### TASK-008: Implement Distance Calculation Utility

**Objective**
Implement `DistanceCalculator` helper to calculate total distance traveled in meters from chronological `LocationPoint` records using `Geolocator.distanceBetween`, returning `Either<TrackingFailure, double>`.

**Changes**
- `lib/domain/utils/distance_calculator.dart`

**Implementation Notes**
- Iterates over sequential coordinate pairs summing distance.
- Return `Right(0.0)` for lists with fewer than 2 points.

**Tests**
- `test/domain/distance_calculator_test.dart`: Test total distance computation across known coordinate pairs and edge cases.

**Acceptance Criteria**
- [ ] Returns accurate distance in meters.
- [ ] Handles empty or single-point lists gracefully returning `Right(0.0)`.
- [ ] Unit tests pass 100%.

---

### TASK-009: Implement UserRoleCubit with HydratedBloc Persistence

**Objective**
Create `UserRoleCubit` managing active user role state (`UserRole.user` vs `UserRole.admin`), persisting role selection across application restarts using `HydratedBloc`.

**Changes**
- `lib/presentation/cubits/user_role_cubit.dart`

**Implementation Notes**
- Inherit from `HydratedCubit<UserRole>`.
- Implement `fromJson` and `toJson` for state serialization.

**Tests**
- `test/presentation/cubits/user_role_cubit_test.dart`: Test role toggle and state restoration.

**Acceptance Criteria**
- [ ] Defaults to `UserRole.user`.
- [ ] Toggling role updates state and serializes to storage.
- [ ] Unit tests pass 100%.

---

### TASK-010: Implement MapCubit for Location Tracking & Polyline Mapping

**Objective**
Create `MapCubit` and `MapState` managing map initialization, GPS location tracking streams, polyline route points, and location permission failures (`LocationPermissionDeniedFailure`).

**Changes**
- `lib/presentation/cubits/map/map_cubit.dart`
- `lib/presentation/cubits/map/map_state.dart`

**Implementation Notes**
- Subscribe to `TrackingRepository.watchLocationPoints()`.
- Use `Option<TrackingFailure>` in `MapState` for functional error representation.

**Tests**
- `test/presentation/cubits/map_cubit_test.dart`: Test state transitions (`MapInitial`, `MapLoading`, `MapLoaded`, `MapFailure`).

**Acceptance Criteria**
- [ ] Location stream updates emit `MapLoaded` with polyline coordinates.
- [ ] Location permission denials emit `MapFailure` containing `LocationPermissionDeniedFailure`.
- [ ] Unit tests pass 100%.

---

### TASK-011: Implement IncidentCubit for Incident Submission

**Objective**
Create `IncidentCubit` and `IncidentState` handling incident form submission (Police, Accident, Traffic Heavy) with coordinates and timestamp, returning `Either<TrackingFailure, Unit>`.

**Changes**
- `lib/presentation/cubits/incident/incident_cubit.dart`
- `lib/presentation/cubits/incident/incident_state.dart`

**Implementation Notes**
- Invokes `TrackingRepository.addIncidentReport()`.
- Emits `IncidentSubmitting`, `IncidentSuccess`, or `IncidentFailure`.

**Tests**
- `test/presentation/cubits/incident_cubit_test.dart`: Test submission success and failure states.

**Acceptance Criteria**
- [ ] Submitting incident logs record locally and enqueues outbox item.
- [ ] Emits `IncidentSuccess` on completion.
- [ ] Unit tests pass 100%.

---

### TASK-012: Implement AdminCubit for Telemetry Metrics & Route Guarding

**Objective**
Create `AdminCubit` and `AdminState` computing total distance traveled in meters and total points count, observing incidents table, and emitting `AdminUnauthorized` when active role is `UserRole.user`.

**Changes**
- `lib/presentation/cubits/admin/admin_cubit.dart`
- `lib/presentation/cubits/admin/admin_state.dart`

**Implementation Notes**
- Check `activeRole`. If `UserRole.user`, emit `AdminUnauthorized` (`UnauthorizedAccessFailure`).
- If `UserRole.admin`, query telemetry metrics and emit `AdminLoaded`.

**Tests**
- `test/presentation/cubits/admin_cubit_test.dart`: Test telemetry calculation and role guard behavior.

**Acceptance Criteria**
- [ ] Non-admin role triggers `AdminUnauthorized`.
- [ ] Admin role loads metric cards data and incident log stream.
- [ ] Unit tests pass 100%.

---

### TASK-013: Create Reusable UI Components

**Objective**
Implement reusable UI widgets: `AppNavigationDrawer` (navigation & role switcher), `TelemetryCard` (metric card widget), `IncidentsTable` (scrollable incident log table), and `IncidentReportDialog` (choices modal for Police, Accident, Traffic Heavy).

**Changes**
- `lib/presentation/widgets/app_navigation_drawer.dart`
- `lib/presentation/widgets/telemetry_card.dart`
- `lib/presentation/widgets/incidents_table.dart`
- `lib/presentation/widgets/incident_report_dialog.dart`

**Implementation Notes**
- Ensure minimum touch target size of 48x48 dp.
- Add explicit `Semantics` tags for accessibility.

**Tests**
- `test/presentation/widgets/widgets_test.dart`: Widget tests verifying drawer interaction, metric card rendering, and incident selection dialog choices.

**Acceptance Criteria**
- [ ] `AppNavigationDrawer` allows switching views and toggling `UserRole`.
- [ ] `IncidentReportDialog` presents 3 distinct choices with icons.
- [ ] Touch targets and semantics satisfy accessibility guidelines.
- [ ] Widget tests pass 100%.

---

### TASK-014: Implement Primary Views & Main Application Entry

**Objective**
Implement `MapView`, `AdminView`, `UnauthorizedView`, and update `lib/main.dart` with `HydratedStorage` initialization, database/repository singletons, and top-level `MultiBlocProvider`.

**Changes**
- `lib/presentation/views/map_view.dart`
- `lib/presentation/views/admin_view.dart`
- `lib/presentation/views/unauthorized_view.dart`
- `lib/main.dart`

**Implementation Notes**
- MapView renders Mapbox map canvas (`streets-v12`) and FAB.
- AdminView renders summary cards and incident table if admin, or `UnauthorizedView` if user.
- Setup `MaterialApp` routes (`/` and `/admin`).

**Tests**
- `test/presentation/views/map_view_test.dart`
- `test/presentation/views/admin_view_test.dart`

**Acceptance Criteria**
- [ ] `MapView` renders live location and polyline route.
- [ ] Navigating to `/admin` as `UserRole.user` renders `UnauthorizedView`.
- [ ] Navigating to `/admin` as `UserRole.admin` displays total distance (in meters) and incident log table.
- [ ] Widget tests pass 100%.

---

### TASK-015: End-to-End Integration Verification

**Objective**
Perform end-to-end integration verification testing: background tracking, offline incident creation, atomic outbox enqueueing, simulated sync console dispatch, admin route guarding, and analyzer checks.

**Changes**
- `test/integration/tracking_e2e_test.dart`

**Implementation Notes**
- Run `flutter analyze` and `flutter test`.

**Tests**
- Complete test suite (`flutter test`).

**Acceptance Criteria**
- [ ] All unit, widget, and integration tests pass 100%.
- [ ] `flutter analyze` reports zero errors and zero warnings.
- [ ] Complete offline-first workflow verified.

---

### TASK-016: Configure Native Background Location Permissions & Manifests

**Objective**
Configure native Android (`AndroidManifest.xml`) and iOS (`Info.plist`) permissions and foreground service declarations required for background location tracking and OS compliance.

**Changes**
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

**Implementation Notes**
- Declare Android permissions: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`.
- Declare `GeolocatorLocationService` with `android:foregroundServiceType="location"` for Android 14+ (API 34+) compliance.
- Declare iOS `UIBackgroundModes` containing `location` and location usage description keys (`NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`).

**Tests**
- Validate XML and Plist structure via `flutter analyze`.

**Acceptance Criteria**
- [ ] `AndroidManifest.xml` contains location and foreground service permissions and service entry.
- [ ] `Info.plist` contains `location` background mode and location usage keys.
- [ ] `flutter analyze` reports zero errors.

