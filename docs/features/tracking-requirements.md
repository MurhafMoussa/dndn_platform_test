# Technical Requirements Specification

## 1. Map & Interactive Canvas
* **Map SDK Integration:** Integrate Mapbox Maps SDK (`mapbox_maps_flutter`) to render the interactive map view and display the user's current live location.
* **Incident Reporting FAB:** Implement a Floating Action Button (FAB) on the map screen that opens an Incident Reporting Form featuring 3 distinct report types:
  * **Police**
  * **Accident**
  * **Traffic Heavy**
* **Incident Capture:** Upon selecting an incident type, capture and persist the report payload containing the incident type, accurate GPS location (latitude/longitude), and exact `DateTime` timestamp.

## 2. Background Location Service
* **Periodic GPS Capturing:** Run a background tracking service that periodically records user GPS coordinates.
* **OS Persistence:** Ensure the background location service continues capturing coordinates reliably when the application is minimized or placed in the background state.

## 3. Offline-First Local Storage
* **Relational Persistence:** Persist all recorded location points and incident reports locally using Drift (SQLite) to ensure zero data loss during network outages or background app execution.
* **Outbox Pattern:** Enqueue outgoing network payloads into a local `sync_outbox` table when offline to enable deterministic synchronization when connectivity is restored.

## 4. Route Polyline Rendering
* **Polyline Mapping:** Render a polyline route across the Mapbox canvas generated dynamically from the chronological list of recorded location points stored in local storage.

## 5. Telemetry & Admin Dashboard Access
* **View-Level Authorization & Role Guarding:** Implement a basic user state/role controller (`UserRole.user` vs `UserRole.admin`) with a simulated role switcher or login guard to restrict access to the dashboard.
* **Admin Route Guarding:** Protect the `/admin` navigation route so that non-admin sessions are redirected to the map view or shown an unauthorized access indicator.
* **Telemetry Metrics:** Provide a simplified Admin Dashboard view available strictly to admin roles, displaying:
  * Total distance traveled
  * Total location points recorded
  * Itemized table of submitted incident reports with timestamps and coordinates

## 6. Additional & Bonus Features
* **Simulated Real-Time Dispatch:** Simulate real-time WebSocket emissions by printing outgoing JSON payloads to the console upon capturing new location points or incident reports.
* **Resilient Permission Management:** Implement explicit foreground and background location permission handlers to gracefully handle denied or restricted permissions without app crashes.