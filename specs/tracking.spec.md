# Feature Specification: Tracking & Incident Reporting

## 1. Problem
Users and system administrators require a reliable, offline-first location tracking and incident reporting system. Field users and drivers need to view their live location, see their traveled polyline route on an interactive map, submit location-stamped incident reports (Police, Accident, Traffic Heavy) via a Floating Action Button (FAB), and have periodic location capturing continue reliably when the application is placed in the background or minimized. System administrators require protected access to a telemetry dashboard to view metrics such as total distance traveled, total location points captured, and an itemized log of reported incidents. Network outages must be handled seamlessly without data loss through local SQLite persistence and an outbox queue.

## 2. User Stories
* **US-1 (Live Location & Interactive Map):** As a user, I want to view my current live location on an interactive Mapbox map so that I can see where I am in real time.
* **US-2 (Route Polyline Mapping):** As a user, I want to see a polyline route rendered on the map generated from my recorded location history so that I can visualize my traveled route.
* **US-3 (Incident Reporting):** As a user, I want to tap a Floating Action Button on the map screen to report an incident (Police, Accident, Traffic Heavy) with my exact GPS coordinates and timestamp so that hazards are logged immediately.
* **US-4 (Background Location Tracking):** As a user, I want location tracking to continue recording coordinates periodically even when the app is in the background or minimized so that my entire journey is recorded without interruption.
* **US-5 (Offline Storage & Synchronization):** As a user, I want all my recorded location points and incident reports stored locally when offline and synchronized automatically when connectivity is restored so that no data is lost during network outages.
* **US-6 (Admin Telemetry Dashboard):** As an administrator, I want to access a telemetry dashboard (`/admin`) displaying total distance traveled, total location points recorded, and an itemized table of submitted incident reports so that I can monitor system telemetry.
* **US-7 (Role-Based Route Guarding):** As a non-admin user, I want access to the `/admin` route restricted so that sensitive telemetry data and administrative features remain protected.

## 3. Functional Requirements
* **FR-1 Map & Polyline View:**
  * FR-1.1: Integrate Mapbox Maps SDK (`mapbox_maps_flutter`) to render an interactive map view displaying the user's current live location.
  * FR-1.2: Render a polyline route across the Mapbox canvas generated dynamically from the chronological list of recorded location points stored in local storage.
* **FR-2 Incident Reporting:**
  * FR-2.1: Display a Floating Action Button (FAB) on the map screen.
  * FR-2.2: Tapping the FAB opens an Incident Reporting Form with 3 distinct incident options: Police, Accident, Traffic Heavy.
  * FR-2.3: Selecting an incident type captures and persists an incident report payload containing incident type, accurate GPS coordinates (latitude, longitude), and exact `DateTime` timestamp.
* **FR-3 Background Location Service:**
  * FR-3.1: Execute a background tracking service configured with a 2-second sampling interval and a 1-meter displacement filter threshold to capture GPS coordinates reliably for device testing.
  * FR-3.2: Ensure background location recording continues when the application is minimized or placed in the background state.
  * FR-3.3: Implement explicit foreground and background location permission handlers to handle denied or restricted permissions gracefully without application crashes.
* **FR-4 Offline Persistence & Outbox Queue:**
  * FR-4.1: Persist all recorded location points and incident reports locally using Drift (SQLite) as the primary source of truth.
  * FR-4.2: Enqueue outgoing mutation payloads into a local `sync_outbox` database table.
  * FR-4.3: Automatically process and flush pending `sync_outbox` entries via a simulated `SyncEngine` transitioning status from pending -> syncing -> synced while printing JSON dispatches to console without requiring an external REST API backend server.
* **FR-5 Admin Telemetry Dashboard & Route Guarding:**
  * FR-5.1: Implement user role controller supporting `UserRole.user` and `UserRole.admin` states, with state persisted across application restarts using `HydratedBloc`.
  * FR-5.2: Provide access to the `/admin` dashboard and role selection through a Navigation Drawer menu.
  * FR-5.3: Protect the `/admin` navigation route so non-admin sessions are redirected to the map view or shown an unauthorized access indicator.
  * FR-5.4: Provide an Admin Dashboard view available strictly to admin roles, displaying:
    * Total distance traveled calculated via Geolocator distance algorithm (`Geolocator.distanceBetween`) formatted in Meters (e.g. "1,250 m")
    * Total location points recorded
    * Itemized table of submitted incident reports with timestamps and coordinates
* **FR-6 Real-Time Dispatch Simulation:**
  * FR-6.1: Print outgoing JSON payloads to the console upon capturing new location points or incident reports to simulate real-time WebSocket emissions.

## 4. UI/UX Requirements
* **UI-1 Map View:**
  * Display full-screen interactive Mapbox view using Mapbox Streets style (`streets-v12`) with Mapbox Access Token injected via `--dart-define` / environment configuration.
  * Render current location marker and dynamic polyline route overlay.
  * Position a Floating Action Button (FAB) on the map screen to trigger incident reporting.
  * Provide a Navigation Drawer menu for app navigation and toggling between `UserRole.user` and `UserRole.admin` roles.
* **UI-2 Incident Reporting Form:**
  * Present a clear selection dialog or sheet with 3 options: Police, Accident, Traffic Heavy.
  * Provide immediate visual feedback (e.g. SnackBar) upon submitting an incident report.
* **UI-3 Admin Dashboard View (`/admin`):**
  * Accessible via Navigation Drawer item when the current session role is `UserRole.admin`.
  * Display summary metric cards for Total Distance Traveled (in Meters) and Total Location Points Recorded.
  * Display an itemized table for Incident Reports showing Type, Timestamp, Latitude, and Longitude columns.
  * Render an unauthorized access indicator or redirect to the map screen when accessed by a non-admin session.
* **UI-4 Styling & Design Patterns:**
  * Adhere to the existing application design system and Material theme.
  * Support explicit UI states across views: loading, error, empty, and success states.

## 5. Non-Functional Requirements
* **NFR-1 Architectural Layering:**
  * Adhere strictly to MVVM architecture: View -> ViewModel/Cubit -> Repository Contract -> Data Sources / Local DB / SyncEngine.
  * ViewModels must not depend on UI widgets (`package:flutter/widgets.dart`), Drift database models, or network clients (`Dio`).
  * Background service must operate independently without depending on Views or ViewModels.
* **NFR-2 Performance & Reactive UI:**
  * Prefer reactive database streams exposed by `TrackingRepository` for automatic UI updates without network or database polling.
  * Maintain efficient background location capturing without excessive battery drain.
* **NFR-3 Data Integrity & Reliability:**
  * Local Drift database is the single authoritative source of truth.
  * Offline writes must be committed to local storage before enqueueing in `sync_outbox`.
  * Synchronization retries must be idempotent to prevent duplicate business records.
  * Synchronization failures must preserve locally persisted data.
* **NFR-4 Access Security:**
  * View-level authorization and route guarding restricting non-admin sessions from accessing telemetry metrics at `/admin`.

## 6. Data Requirements
* **Relational Database Schemas (Drift / SQLite):**
  * `location_points`:
    * `id`: TEXT PRIMARY KEY
    * `latitude`: REAL NOT NULL
    * `longitude`: REAL NOT NULL
    * `timestamp`: INTEGER NOT NULL
  * `incidents`:
    * `id`: TEXT PRIMARY KEY
    * `type`: TEXT NOT NULL ('Police', 'Accident', 'Traffic Heavy')
    * `latitude`: REAL NOT NULL
    * `longitude`: REAL NOT NULL
    * `timestamp`: INTEGER NOT NULL
  * `sync_outbox`:
    * `id`: TEXT PRIMARY KEY
    * `event_type`: TEXT NOT NULL
    * `payload`: TEXT NOT NULL (JSON string)
    * `created_at`: INTEGER NOT NULL
    * `status`: TEXT NOT NULL ('pending', 'syncing', 'failed')
* **Domain Models & Enums:**
  * `UserRole`: `user`, `admin`.
  * Clean domain model representations for LocationPoint, IncidentReport, and SyncOutboxItem separate from generated Drift database row classes.

## 7. Offline-First Behavior
* **Local First Reads:** UI components read and stream location points, polylines, and incident logs directly from local Drift tables via `TrackingRepository`. Active internet connection is not required to display local data.
* **Offline Writes:** When a new location point is recorded or an incident is logged offline, the data is written to local Drift tables in a transaction along with an outbox item in `sync_outbox`.
* **Outbox Processing:** `SyncEngine` monitors network availability. When connected, pending outbox records are processed sequentially. Failed attempts mark records as 'failed' without deleting local business records.

## 8. Failure Scenarios
* **Permission Denied / Restricted:** If location permission is denied by the user, handle gracefully with a notification/banner and disable background tracking without causing application crashes.
* **GPS Fix Unavailable / Timeout:** Handle GPS unavailable or timed-out states gracefully in the location service without throwing unhandled exceptions.
* **Network Unavailable During Incident Submission:** Save the incident report locally in `incidents` and `sync_outbox`, present success UI feedback immediately, and sync when online.
* **Unauthorized Navigation to `/admin`:** If a `UserRole.user` attempts to navigate to `/admin`, intercept via route guard and redirect to the map view or display an unauthorized access indicator.
* **Sync Server Error / Timeout:** Outbox retry logic preserves local data and flags outbox entry status as 'failed' for subsequent retry.

## 9. Acceptance Criteria
* **AC-1 Map & Polyline View:**
  * Map view renders interactive Mapbox map with current live location.
  * Polyline route connects recorded local location points chronologically.
* **AC-2 Incident Reporting:**
  * FAB on map view opens Incident Reporting Form with Police, Accident, and Traffic Heavy choices.
  * Selecting an incident type captures coordinates and timestamp, persisting to `incidents` table and `sync_outbox`.
* **AC-3 Background Location Capture:**
  * Location service captures coordinates periodically in background/minimized states and writes to local storage.
  * Permission denials are handled gracefully.
* **AC-4 Admin Dashboard & Route Guarding:**
  * Navigating to `/admin` as `UserRole.admin` displays total distance, total location points, and incident table.
  * Navigating to `/admin` as `UserRole.user` redirects or presents unauthorized access indicator.
* **AC-5 Simulated Real-Time Dispatch:**
  * Outgoing JSON payload is printed to console on new location points or incident reports.

## 10. Testing Requirements
* **Unit Tests:**
  * `TrackingRepository`: insert location points, create incident reports, and enqueue outbox payloads.
  * Telemetry calculations: test total distance calculation formula based on chronological location points.
  * ViewModels / Cubits: test MapViewModel presentation states, incident submission flow, and AdminViewModel telemetry & role guard states.
  * `SyncEngine`: test processing pending outbox entries and handling failure retries.
* **Widget Tests:**
  * Map screen rendering and FAB tap handling.
  * Incident Reporting Form options and submission trigger.
  * Admin Dashboard metric cards and itemized incident table.
  * Unauthorized route guard UI view.
* **Integration Tests:**
  * Drift database persistence, reactive stream emissions, and transaction outbox enqueueing.

## 11. Open Questions
None. All architectural, configuration, and feature parameters have been explicitly resolved:

| Decision Area | Selected Parameter / Behavior |
| --- | --- |
| **GPS Sampling Interval & Filter** | 2-second sampling interval with a 1-meter displacement filter threshold for real-time mobile testing. |
| **Distance Calculation & Unit** | `Geolocator.distanceBetween` algorithm displaying total distance in Meters (e.g. "1,250 m"). |
| **Mapbox Style & Access Token** | Mapbox Streets style (`streets-v12`) with access token injected securely via `--dart-define`. |
| **Outbox Network Synchronization** | Simulated `SyncEngine` transitioning outbox state (`pending` -> `syncing` -> `synced`) with console dispatch logging (no real REST API backend required). |
| **Admin Entry Point & Role State** | Navigation Drawer entry point for `/admin`; user role state (`UserRole.user` vs `UserRole.admin`) persisted across app restarts using `HydratedBloc`. |
