# Feature Architecture & Implementation Plan: Initial Location, Real-Time Incident Markers, and Navigation UX

## 1. Architecture

The application follows the established **MVVM (Model-View-ViewModel)** pattern with Cubit state management, local Drift/SQLite persistence, and reactive streams.

### Architectural Flow & Focus Target Navigation

```
[IncidentsTable in AdminView]
       │
       ▼ (Taps "View on Map")
[GoRouter Navigation: /?lat=33.5138&lng=36.2765]
       │
       ▼
[MapCubit.focusLocation(lat, lng)]
       │
       ▼
[MapLoaded state emitted with cameraFocusTarget]
       │
       ▼
[MapView / MapCanvas executes mapboxMap.flyTo()]
       │
       ▼ (Taps "My Location" FAB)
[MapCubit.recenterToUserLocation()] ──► [Fly camera back to currentLocation]
```

---

## 2. Files to Create

### Presentation Layer (New Widgets & Components)
* `lib/presentation/widgets/my_location_button.dart`: Mini Floating Action Button / overlay button to trigger map camera recentering back to live user position.
* `lib/presentation/widgets/admin_telemetry_explanation_card.dart`: Responsive card/tooltip widget placed in `/admin` explaining location points and distance calculation telemetry.

### Test Files
* `test/presentation/widgets/my_location_button_test.dart`: Widget test for recenter button rendering and tap callback.
* `test/presentation/widgets/admin_telemetry_explanation_card_test.dart`: Widget test for Admin telemetry explanations and tooltips.

---

## 3. Files to Modify

* `lib/core/constants/app_strings.dart`: Add string constants for Admin Dashboard explanations ("What are Location Points?"), "View on Map" button text, and "My Location" tooltips.
* `lib/presentation/navigation/app_router.dart`: Support optional `lat` and `lng` query parameters on `/` route so navigating from `/admin` to `/` focuses on specific coordinates.
* `lib/presentation/cubits/map/map_state.dart`: Add `CameraFocusTarget? cameraFocusTarget` field to `MapLoaded` state.
* `lib/presentation/cubits/map/map_cubit.dart`:
  * Update `initializeMap()` to request location permission on app startup and acquire initial live position fix.
  * Add `focusLocation(double latitude, double longitude)` method.
  * Add `recenterToUserLocation()` method.
* `lib/presentation/views/map_view.dart`:
  * Add `MyLocationButton` overlay on map screen.
  * Handle incoming query parameters from router or state changes to fly camera to focus target.
* `lib/presentation/widgets/map_canvas.dart`:
  * Remove breadcrumb popup dialogs from map overlay card.
  * Render real-time incident markers using Mapbox `CircleAnnotationManager`.
* `lib/presentation/widgets/map_status_card.dart`: Clean up status card layout to show concise live stats without cluttered explanatory popups.
* `lib/presentation/views/admin_view.dart` & `lib/presentation/widgets/admin_telemetry_overview.dart`:
  * Integrate `AdminTelemetryExplanationCard` responsively in `/admin`.
* `lib/presentation/widgets/incidents_table.dart`:
  * Add "View on Map" button to each incident card/row.
  * Trigger callback to navigate to map with incident coordinates.
* `test/presentation/cubits/map_cubit_test.dart`: Add unit tests for initial launch permission check, camera focus, and recentering.
* `test/presentation/views/map_view_test.dart`: Update widget tests for "My Location" button and clean map status layout.

---

## 4. Data Model

### Camera Focus Target Value Object (`lib/presentation/cubits/map/map_state.dart`)

```dart
class CameraFocusTarget extends Equatable {
  final double latitude;
  final double longitude;
  final double zoom;

  const CameraFocusTarget({
    required this.latitude,
    required this.longitude,
    this.zoom = 16.0,
  });

  @override
  List<Object?> get props => [latitude, longitude, zoom];
}
```

---

## 5. Repository API

No repository API breaking changes required. Uses existing `TrackingRepository` methods:
* `watchLocationPoints()`
* `watchIncidents()`
* `addLocationPoint()`
* `addIncidentReport()`

---

## 6. ViewModel API (`MapCubit`)

```dart
class MapCubit extends Cubit<MapState> {
  final TrackingRepository repository;
  final LocationService locationService;

  MapCubit({
    required this.repository,
    required this.locationService,
  }) : super(const MapInitial());

  /// Initializes map, requests location permissions immediately on start,
  /// acquires initial position fix, and observes location & incident streams.
  Future<void> initializeMap();

  /// Sets camera target focus coordinates (e.g. focused on a specific incident).
  void focusLocation(double latitude, double longitude, {double zoom = 16.0});

  /// Resets camera target back to current live user location.
  Future<void> recenterToUserLocation();

  /// Starts background GPS location tracking.
  Future<void> startTracking();

  /// Stops background GPS location tracking.
  Future<void> stopTracking();
}
```

---

## 7. Presentation Architecture

```
                               ┌────────────────────────────────┐
                               │           AppRouter            │
                               │  / (Map)   │   /admin (Admin)  │
                               └──────┬─────────────────┬───────┘
                                      │                 │
                      ┌───────────────┴──┐           ┌──┴───────────────┐
                      │     MapView      │           │    AdminView     │
                      │  - MapCanvas     │           │  - Summary Cards │
                      │  - Status Card   │           │  - Explanations  │
                      │  - MyLocation FAB│           │  - IncidentsTable│
                      │  - Hazard FAB    │           │    ("View on Map")│
                      └──────────────────┘           └──────────────────┘
```

---

## 8. UI States (`MapLoaded`)

```dart
class MapLoaded extends MapState {
  final List<LocationPoint> locationPoints;
  final List<IncidentReport> incidents;
  final LocationPoint? currentLocation;
  final CameraFocusTarget? cameraFocusTarget;
  final bool isTracking;

  const MapLoaded({
    required this.locationPoints,
    this.incidents = const [],
    this.currentLocation,
    this.cameraFocusTarget,
    this.isTracking = false,
  });
}
```

---

## 9. Reusable Components

* `MyLocationButton`: Floating circular icon button (`Icons.my_location_rounded`) positioned above the Hazard FAB.
* `AdminTelemetryExplanationCard`: Expandable / info card explaining location points and total distance telemetry metrics within `/admin`.
* `IncidentsTable`: Itemized incident table with an added "View on Map" action button on each row/card.

---

## 10. Responsive Behavior

* **Mobile Form Factor (< 600dp)**:
  * Incident cards in `/admin` display "View on Map" as a compact icon button with map pin (`Icons.location_on_outlined`).
  * Telemetry explanation card renders vertically stacked.
* **Tablet / Wide Form Factor (>= 600dp)**:
  * Incident table displays an explicit "View on Map" text button with icon.
  * Admin telemetry explanations render side-by-side using `Row` or responsive grid.

---

## 11. Accessibility Considerations

* **Semantic Tags**: `Semantics(label: 'Recenter camera to my live location', button: true)` on `MyLocationButton`.
* **Touch Targets**: All action buttons maintain minimum dimensions of 48x48 dp.
* **Color Contrast**: Distinct high-contrast colors for incident markers (Police = `#1E88E5`, Accident = `#E53935`, Traffic = `#FB8C00`) with white stroke borders for legibility on map tiles.

---

## 12. Offline-First Flow

1. Initial GPS location fix works via local device hardware without network connectivity.
2. Incident markers render directly from local Drift database streams (`watchIncidents()`).
3. Camera panning, focusing on incident coordinates, and recentering to live location operate fully offline.

---

## 13. Sync Behavior

* Submitting an incident logs the report to local database and enqueues a payload in `sync_outbox`.
* The incident marker appears immediately on the local map canvas before outbox sync executes.

---

## 14. Testing Strategy

* **Unit Tests**:
  * `MapCubit`: Test `initializeMap()` requesting permissions and setting initial location, `focusLocation()`, `recenterToUserLocation()`, and `watchIncidents()` emission.
* **Widget Tests**:
  * `MyLocationButton`: Verify tap triggers recenter callback.
  * `IncidentsTable`: Verify "View on Map" button renders and invokes navigation callback.
  * `AdminTelemetryExplanationCard`: Verify telemetry explanations render correctly in `/admin`.
* **Integration Tests**:
  * E2E flow: Launch app -> prompt location -> submit incident -> verify immediate marker -> navigate via incident card -> tap "My Location".

---

## 15. Risks

* **Permission Denial on Startup**: User rejects location permission prompt at launch.
  * *Mitigation*: Handle gracefully by displaying permission retry banner and using Syria fallback coordinates until permission is granted.
* **Rapid Camera Jump Conflict**: User taps "My Location" while map is animating to an incident.
  * *Mitigation*: Cancel ongoing camera animation before initiating a new camera transition.

---

## 16. Migration Considerations

* No database schema migrations required (uses existing Drift schema v1).
* Preserves all established MVVM architecture guidelines and test suite compatibility.
