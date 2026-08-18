# Implementation Tasks: Initial Location, Real-Time Incident Markers, and Navigation UX

## Task List & Dependency Order

1. **TASK-001**: Define Camera Focus Target Model and UI Strings
2. **TASK-002**: Update MapCubit for Initial Location Fix and Camera Navigation
3. **TASK-003**: Create MyLocationButton Component
4. **TASK-004**: Create AdminTelemetryExplanationCard Component
5. **TASK-005**: Update MapCanvas and MapStatusCard for Real-Time Incident Markers and Clean UI
6. **TASK-006**: Add "View on Map" Action to IncidentsTable
7. **TASK-007**: Update AppRouter and MapView Integration
8. **TASK-008**: End-to-End Integration Verification & Testing

---

### TASK-001: Define Camera Focus Target Model and UI Strings

**Objective**
Define the `CameraFocusTarget` value object in `map_state.dart` and add string constants to `app_strings.dart` for Admin Dashboard telemetry explanations, "View on Map" buttons, and "My Location" accessibility tooltips.

**Changes**
- `lib/presentation/cubits/map/map_state.dart`: Add `CameraFocusTarget` class and `cameraFocusTarget` property to `MapLoaded`.
- `lib/core/constants/app_strings.dart`: Add string constants (`viewOnMap`, `myLocation`, `telemetryExplanationsTitle`, `telemetryExplanationsBody`, etc.).

**Implementation Notes**
- Keep `CameraFocusTarget` immutable, extending `Equatable`.
- Ensure `MapLoaded.copyWith` handles `cameraFocusTarget`.

**Tests**
- `test/presentation/cubits/map_cubit_test.dart`: Test `CameraFocusTarget` instantiation and `MapLoaded` equality.

**Acceptance Criteria**
- [ ] `CameraFocusTarget` model contains `latitude`, `longitude`, and `zoom` properties.
- [ ] `MapLoaded` state holds optional `cameraFocusTarget` property.
- [ ] UI string constants are available in `AppStrings`.

---

### TASK-002: Update MapCubit for Initial Location Fix and Camera Navigation

**Objective**
Update `MapCubit` to trigger location permission check/request on start, fetch initial live location fix, and provide `focusLocation(lat, lng)` and `recenterToUserLocation()` API methods.

**Changes**
- `lib/presentation/cubits/map/map_cubit.dart`:
  - Update `initializeMap()` to request location permission on app boot and acquire initial position.
  - Implement `focusLocation(double latitude, double longitude, {double zoom = 16.0})`.
  - Implement `recenterToUserLocation()`.

**Implementation Notes**
- When `focusLocation` is called, update `MapLoaded` state with `cameraFocusTarget`.
- When `recenterToUserLocation` is called, set `cameraFocusTarget` back to `currentLocation` coordinates.

**Tests**
- `test/presentation/cubits/map_cubit_test.dart`:
  - Test `initializeMap()` requests permission and emits `currentLocation`.
  - Test `focusLocation()` emits `MapLoaded` with `cameraFocusTarget`.
  - Test `recenterToUserLocation()` updates `cameraFocusTarget` to user location.

**Acceptance Criteria**
- [ ] `initializeMap()` requests location permission immediately on boot.
- [ ] `focusLocation(lat, lng)` emits updated `MapLoaded` with focus target.
- [ ] `recenterToUserLocation()` emits updated `MapLoaded` pointing to user's live position.

---

### TASK-003: Create MyLocationButton Component

**Objective**
Create a reusable `MyLocationButton` overlay widget that renders a mini FAB / circular icon button (`Icons.my_location_rounded`) to trigger camera recentering.

**Changes**
- `lib/presentation/widgets/my_location_button.dart`: Create new widget file (< 100 lines).

**Implementation Notes**
- Apply `Semantics(label: 'Recenter camera to my live location', button: true)`.
- Ensure minimum touch target size of 48x48 dp.

**Tests**
- `test/presentation/widgets/my_location_button_test.dart`: Widget test verifying button rendering and tap callback trigger.

**Acceptance Criteria**
- [ ] `MyLocationButton` renders cleanly with location icon.
- [ ] Tapping `MyLocationButton` invokes `onPressed` callback.
- [ ] Complies with widget size constraints (< 100 lines) and accessibility standards.

---

### TASK-004: Create AdminTelemetryExplanationCard Component

**Objective**
Create an `AdminTelemetryExplanationCard` component widget in `/admin` that presents clear, responsive explanations for location points and distance metrics.

**Changes**
- `lib/presentation/widgets/admin_telemetry_explanation_card.dart`: Create new widget file (< 100 lines).

**Implementation Notes**
- Include explanations for "Total Location Points" and "Total Distance Traveled".
- Adapt layout responsively for mobile (< 600dp) and tablet (>= 600dp) form factors.

**Tests**
- `test/presentation/widgets/admin_telemetry_explanation_card_test.dart`: Widget test verifying telemetry explanation rendering.

**Acceptance Criteria**
- [ ] Renders telemetry explanations for GPS points and distance calculations in `/admin`.
- [ ] Adapts responsively across mobile and tablet screen widths.

---

### TASK-005: Update MapCanvas and MapStatusCard for Real-Time Incident Markers and Clean UI

**Objective**
Remove breadcrumb explanation popups from `MapStatusCard`, and render real-time incident markers on `MapCanvas` via Mapbox `CircleAnnotationManager`.

**Changes**
- `lib/presentation/widgets/map_canvas.dart`:
  - Render incident markers using `CircleAnnotationManager` color-coded by type.
  - Listen for camera focus changes and invoke `mapboxMap.flyTo()` when `cameraFocusTarget` changes.
- `lib/presentation/widgets/map_status_card.dart`: Clean up status overlay to display concise live telemetry stats without explanation popups.

**Implementation Notes**
- Circle markers: Police = Blue (`#1E88E5`), Accident = Red (`#E53935`), Traffic = Orange (`#FB8C00`).
- Ensure widget files remain under 150 lines.

**Tests**
- `test/presentation/views/map_view_test.dart`: Update widget tests to verify clean status card and incident marker rendering.

**Acceptance Criteria**
- [ ] Incident reports appear immediately on `MapCanvas` as color-coded markers.
- [ ] Map status card displays concise live metrics without breadcrumb explanation popups.
- [ ] Camera animates to focus coordinates when target changes.

---

### TASK-006: Add "View on Map" Action to IncidentsTable

**Objective**
Update `IncidentsTable` to render a "View on Map" action button on each incident report card/row that invokes a navigation callback with incident coordinates.

**Changes**
- `lib/presentation/widgets/incidents_table.dart`: Add "View on Map" button to table rows / incident cards.

**Implementation Notes**
- Responsive presentation: Compact icon button (`Icons.location_on_outlined`) on mobile (< 600dp); text button on tablet (>= 600dp).

**Tests**
- `test/presentation/widgets/widgets_test.dart`: Test "View on Map" button rendering and callback invocation.

**Acceptance Criteria**
- [ ] Each incident card/row in `IncidentsTable` contains a "View on Map" button.
- [ ] Tapping "View on Map" triggers callback with incident latitude and longitude.

---

### TASK-007: Update AppRouter and MapView Integration

**Objective**
Configure `AppRouter` to accept optional `lat` and `lng` query parameters on `/`, pass them to `MapCubit.focusLocation()`, and integrate `MyLocationButton` on `MapView`.

**Changes**
- `lib/presentation/navigation/app_router.dart`: Support `/?lat=...&lng=...` query parameters.
- `lib/presentation/views/map_view.dart`: Integrate `MyLocationButton` overlay and camera focus listener.
- `lib/presentation/views/admin_view.dart`: Connect `IncidentsTable` "View on Map" callback to navigate to `/?lat=...&lng=...`.

**Implementation Notes**
- Navigating from `/admin` to `/?lat=33.51&lng=36.27` switches tabs and moves map camera to the target incident.

**Tests**
- `test/presentation/views/map_view_test.dart`: Test `MapView` rendering with `MyLocationButton`.
- `test/presentation/views/admin_view_test.dart`: Test tapping "View on Map" in `AdminView`.

**Acceptance Criteria**
- [ ] Navigating to `/?lat=...&lng=...` focuses map camera on target coordinates.
- [ ] Tapping "My Location" on `MapView` re-centers camera to live user location.
- [ ] Tapping "View on Map" in `/admin` navigates to map view focused on incident.

---

### TASK-008: End-to-End Integration Verification & Testing

**Objective**
Execute static analysis (`flutter analyze`) and full test suite (`flutter test`) to verify all tasks pass cleanly with zero analyzer warnings or failing tests.

**Changes**
- Integration tests & test suite execution.

**Implementation Notes**
- Ensure zero analyzer warnings or errors.

**Tests**
- Full unit, widget, and integration test suite (`flutter test`).

**Acceptance Criteria**
- [ ] `flutter analyze` completes with zero issues.
- [ ] All unit, widget, and integration tests pass successfully.
