# Technical Requirements Specification

## 1. Map & Interactive Canvas
* **Map SDK Integration:** Integrate Mapbox Maps SDK (`mapbox_maps_flutter`) using Mapbox Streets style (`streets-v12`) to render the interactive map view and display the user's current live location.
* **Incident Reporting FAB:** Implement a Floating Action Button (FAB) on the map screen that opens an Incident Reporting Form featuring 3 distinct report types:
  * **Police**
  * **Accident**
  * **Traffic Heavy**
* **Incident Capture:** Upon selecting an incident type, capture and persist the report payload containing the incident type, accurate GPS location (latitude/longitude), and exact `DateTime` timestamp.

## 2. Background Location Service
* **Periodic GPS Capturing:** Run a background tracking service configured with a 2-second sampling interval and 1-meter displacement filter threshold to record GPS coordinates.
* **OS Persistence:** Ensure the background location service continues capturing coordinates reliably when the application is minimized or placed in the background state.
* **Resilient Permission Management:** Handle foreground and background location permission denials gracefully, mapping errors to `LocationPermissionDeniedFailure` without crashing.

## 3. Offline-First Local Storage
* **Relational Persistence:** Persist all recorded location points and incident reports locally using Drift (SQLite) as the single source of truth.
* **Outbox Pattern:** Enqueue outgoing network payloads into a local `sync_outbox` table when offline to enable deterministic synchronization when connectivity is restored.
* **Sync Engine Processing:** Process `sync_outbox` entries transitioning status (`pending` -> `syncing` -> `synced` / `failed`). Preserve local data intact on sync failures.

## 4. Route Polyline Rendering
* **Polyline Mapping:** Render a polyline route across the Mapbox canvas generated dynamically from the chronological list of recorded location points stored in local storage.

## 5. Telemetry & Admin Dashboard Access
* **Role State Persistence:** Manage user state (`UserRole.user` vs `UserRole.admin`) with persistent storage across application restarts via `HydratedBloc`.
* **Navigation Drawer:** Provide a Navigation Drawer menu for primary navigation and toggling user roles.
* **Admin Route Guarding:** Protect the `/admin` navigation route so that non-admin sessions are redirected to the map view or shown `UnauthorizedView`.
* **Telemetry Metrics:** Provide an Admin Dashboard view available strictly to admin roles, displaying:
  * Total distance traveled in meters calculated via `Geolocator.distanceBetween` (e.g. "1,250 m")
  * Total location points recorded
  * Itemized table of submitted incident reports with timestamps and coordinates

## 6. Simulated Real-Time Dispatch
* **Console Emission:** Print outgoing JSON payloads to console upon processing outbox items to simulate real-time WebSocket dispatch without requiring an external backend server.