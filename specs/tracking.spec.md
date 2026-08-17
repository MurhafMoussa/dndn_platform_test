# Technical Specification: Tracking & Incident Reporting Feature

## 1. Problem
Users of the field tracking system require a reliable, offline-first application that records their real-time location and path history in both foreground and background states. In addition, users need a fast and seamless way to report critical incidents (such as Police, Accidents, or Heavy Traffic) while on the move. 

Because field operations often occur in areas with poor, intermittent, or completely absent cellular coverage, relying on an active network connection for capturing locations or reporting incidents leads to data loss, application hangs, or disrupted tracking. 

Therefore, the system must utilize an offline-first architecture where the local database is the primary source of truth, queuing unsynchronized telemetry and reports in a sync outbox, while maintaining user safety and preventing data loss. Administrators also need a consolidated Telemetry and Admin Dashboard to view key metrics such as distance traveled and incident details in real time.

---

## 2. User Stories
* **As a field user**, I want the app to periodically record my GPS coordinates in both foreground and background states (even when minimized or offline), so that my complete journey is documented without gaps.
* **As a field user**, I want to visualize my recorded trip on an interactive map using a chronological route polyline, so that I can easily verify my traveled path.
* **As a field user**, I want to quickly report incidents (Police, Accident, Traffic Heavy) with a single tap using a Floating Action Button on the map, so that dispatchers are immediately aware of my environment's hazards.
* **As a field user**, I want my reported incidents and location telemetry to be saved locally when I am offline, and automatically synchronized to the dispatch system once my connection is restored, so that I don't have to manually resend them or worry about losing my logs.
* **As an administrator**, I want to view an Admin Dashboard presenting consolidated telemetry—including total distance traveled, total location points recorded, and a chronological table of submitted incident reports—so that I can monitor and analyze field activities efficiently.

---

## 3. Functional Requirements

### 3.1. Interactive Map View & Canvas
* **Map SDK Integration:** The application must integrate the Mapbox Maps SDK (`mapbox_maps_flutter`) to render an interactive map view showing the user's live position.
* **Incident Reporting FAB:** A Floating Action Button (FAB) must be present on the map screen, which opens an Incident Reporting Dialog or Form.
* **Incident Reporting Form:** The form must offer exactly 3 distinct, selectable incident report types:
  * **Police**
  * **Accident**
  * **Traffic Heavy**
* **Incident Capture:** Upon selecting one of the incident types, the application must immediately capture:
  * Incident Type (e.g., `Police`, `Accident`, `Traffic Heavy`)
  * Precise GPS coordinates (Latitude and Longitude)
  * Exact `DateTime` timestamp
* **Route Polyline Mapping:** The map canvas must dynamically render a polyline route connecting all recorded location points in chronological order from local storage.

### 3.2. Background Location Tracking
* **Periodic Capture:** The background location tracking service must periodically record user GPS coordinates (Latitude, Longitude, and timestamp).
* **OS Persistence:** The background tracking service must reliably continue recording coordinates when the application is minimized, placed in the background state, or the device screen is locked.
* **Permission Management:** The app must implement explicit handlers for location permissions:
  * Foreground location permission.
  * Background location permission.
  * Gracefully handle denied or restricted permissions without application crashes or freezes.

### 3.3. Offline-First Local Storage
* **Relational Persistence:** Persist all recorded location points and incident reports locally using Drift (SQLite) to ensure zero data loss.
* **Outbox Pattern:** When offline, any outgoing synchronization payloads (location updates, incident reports) must be enqueued into a local `sync_outbox` table to enable deterministic, chronological synchronization when internet connectivity is restored.

### 3.4. Telemetry & Admin Dashboard
* **Admin Access Layer:** Provide a simplified Admin Dashboard view, accessible via the user interface.
* **Telemetry Metrics:** The dashboard must display:
  * **Total distance traveled:** Aggregated distance calculated chronologically from recorded location points using a spherical distance algorithm (e.g., Haversine).
  * **Total location points recorded:** Count of all stored GPS coordinates.
  * **Itemized Incidents Table:** An itemized, scrollable table of all submitted incident reports displaying their timestamps, incident types, and latitude/longitude coordinates.

### 3.5. Real-Time Dispatch Simulation (Bonus Feature)
* **WebSocket Simulation:** Log outgoing JSON payloads to the console upon capturing new location points or incident reports to simulate real-time WebSocket emissions.

---

## 4. Non-Functional Requirements
* **Architecture:** Rigorously follow the MVVM architecture:
  * **Views:** Render the Mapbox canvas, Incident FAB, dialogs, and Admin Dashboard. Must never access repositories or database drivers directly.
  * **ViewModels:** Manage UI state (e.g., map load state, location tracking toggle, dialog visibility, permissions, dashboard metrics) and coordinate repository calls. Views bind to ViewModels (via Bloc/Cubit).
  * **Repositories:** Act as the offline-first coordination layer between local storage (Drift database) and remote synchronization outboxes.
  * **Data Sources:** Local database (Drift) and remote simulator.
* **Offline Independence:** The application must remain fully functional in offline mode, allowing route visualization (cached points), incident creation, and dashboard telemetry navigation without an active network connection.
* **Robustness & Stability:** Zero application crashes under restricted, denied, or toggled location permission settings.
* **Performance:** Location recording and local persistence must run efficiently without blocking the UI thread or causing frame drops on the map view.

---

## 5. Data Requirements

### 5.1. Database Engine
* **Drift / SQLite** as the persistent local database engine. Do not use HydratedBloc for primary business data.

### 5.2. Entities & Schema Definitions
The database schema must include three main tables:

#### 5.2.1. `LocationPoints` (Table)
* `id`: `Int` (Primary Key, AutoIncrement)
* `latitude`: `Real` (Not Null)
* `longitude`: `Real` (Not Null)
* `timestamp`: `Int` (Not Null, Unix timestamp representation of `DateTime`)

#### 5.2.2. `IncidentReports` (Table)
* `id`: `Text` (Primary Key, UUID string representation)
* `type`: `Text` (Not Null, restricted to: 'police', 'accident', 'traffic_heavy')
* `latitude`: `Real` (Not Null)
* `longitude`: `Real` (Not Null)
* `timestamp`: `Int` (Not Null, Unix timestamp representation of `DateTime`)

#### 5.2.3. `SyncOutbox` (Table)
* `id`: `Int` (Primary Key, AutoIncrement)
* `payloadType`: `Text` (Not Null, e.g., 'location_point' or 'incident_report')
* `payload`: `Text` (Not Null, JSON-serialized string of the event data)
* `createdAt`: `Int` (Not Null, Unix timestamp of enqueue)
* `retryCount`: `Int` (Not Null, Default `0`)

---

## 6. Offline-First Behavior

### 6.1. Local Writes
When a new coordinate is captured by the tracking service or an incident is reported by the user:
1. Validate the operation inputs (e.g., GPS coordinates are valid floats).
2. Persist the record directly in its respective local table (`LocationPoints` or `IncidentReports`).
3. Enqueue a synchronization request into the `SyncOutbox` table.
4. Notify the ViewModels to update the UI (map polyline and Admin Dashboard) directly from local database streams.
5. Attempt immediate synchronization if online.

### 6.2. Synchronization Engine
* The sync engine must query the `SyncOutbox` table for pending records in chronological order (`id` or `createdAt` ascending).
* For each outbox item, it attempts delivery (simulated via WebSockets / Console log dispatch).
* **On Sync Success:** The outbox item is permanently deleted from the `SyncOutbox` table.
* **On Sync Failure:** The outbox item remains in the database, its `retryCount` is incremented, and the synchronization process is rescheduled.
* **Local Data Retention:** Under no circumstances should local data (`LocationPoints` or `IncidentReports`) be deleted or modified when a sync operation fails.

---

## 7. Failure Scenarios

### 7.1. Denied Location Permissions
* **Foreground Denied:** If foreground permission is denied, map initialization shows a fallback screen instructing the user to enable permissions. The location FAB and start tracking options are disabled.
* **Background Denied:** If foreground is approved but background is denied, the application records location only in the foreground and presents a banner/dialog explaining that background tracking is disabled.
* **No Crash Guarantee:** Gracefully handle any permission updates in OS settings without application state corruption or crash.

### 7.2. Temporary GPS Drift / Outage
* If GPS signal is lost temporarily:
  * The tracking service logs a warning.
  * No erratic/zero coordinates (e.g., lat: 0.0, long: 0.0) should be written to the database.
  * The map marker shows the last known position.

### 7.3. Network Failure during Synchronization
* If the internet connection drops mid-sync:
  * The sync engine catches the network exception.
  * It marks the current sync batch as failed.
  * The outbox items are preserved intact.
  * Sync is retried when network connectivity transitions from offline to online.

### 7.4. Database Write Failure
* Database writes must be atomic.
* If a write to `LocationPoints` fails, the outbox entry is not written, ensuring there is never an orphaned sync payload without a corresponding local record.

---

## 8. Acceptance Criteria

### 8.1. Map & Interactive Canvas
* [ ] Mapbox Maps SDK initialized successfully and renders interactive map canvas.
* [ ] Chronological route polyline is drawn on the map, matching stored `LocationPoints` in local Drift database.
* [ ] Map FAB is accessible and opens the Incident Form with 3 distinct options (Police, Accident, Traffic Heavy).

### 8.2. Background Location Tracking
* [ ] GPS tracking runs in background state and periodically records coordinates.
* [ ] Background service persists location coordinates to local database successfully.
* [ ] App does not crash when location permissions are denied, disabled, or changed mid-run.

### 8.3. Offline-First Persistence & Sync
* [ ] Location coordinates and incident reports are stored locally in the Drift database before sync attempt.
* [ ] Going offline, reporting an incident, and restarting the app preserves the incident on the map and the Admin Dashboard.
* [ ] Simulated dispatch prints outgoing JSON to console immediately when capturing location/incidents while online.
* [ ] When offline, outgoing payloads are enqueued in `SyncOutbox`. Returning online triggers outbox sync, clears the outbox, and logs JSON payloads to the console.

### 8.4. Telemetry & Admin Dashboard
* [ ] Simplified Admin Dashboard view is accessible from the main UI.
* [ ] Total distance traveled displays accurately (calculated chronologically from stored location coordinates).
* [ ] Total location points recorded displays the correct, up-to-date count.
* [ ] An itemized table shows all submitted incident reports with accurate timestamps, incident types, and coordinates.

---

## 9. Testing Requirements

### 9.1. Unit Tests
* **Serialization / Deserialization:** Verify JSON encoding/decoding of location points, incident reports, and outbox schema models.
* **Telemetry Aggregation Logic:** Unit test the distance calculation algorithm (e.g., Haversine formula) using simulated chronological coordinate series.
* **ViewModel State Transitions:** Test the tracking ViewModel transitions (e.g., `Idle`, `TrackingActive`, `PermissionsDenied`, `Syncing`).

### 9.2. Integration Tests
* **Local Relational Database:** Test Drift database schema creation, table relationships, CRUD transactions, and data persistence after simulated application restarts.
* **Sync Outbox & Sync Engine:** Test outbox enqueuing, chronological processing, successful deletion on sync success, and retry-count increments on sync failure using simulated connectivity switches.

### 9.3. End-to-End (E2E) Tests
* **Critical Path 1: Start Tracking & Location Logging:**
  1. Open application.
  2. Grant location permissions.
  3. Start location tracking.
  4. Generate simulated GPS coordinates.
  5. Verify polyline rendered on map canvas.
  6. Verify coordinates saved in SQLite database.
* **Critical Path 2: Offline Incident Capture & Online Synchronization:**
  1. Open map screen.
  2. Simulate network disconnection (offline).
  3. Tap FAB and submit a "Police" incident report.
  4. Verify incident is persisted locally and displayed on the map/dashboard.
  5. Verify sync payload is enqueued in `SyncOutbox`.
  6. Simulate network reconnection (online).
  7. Verify outbox synchronization triggers, console log simulation executes, and `SyncOutbox` table becomes empty.

---

## 10. Open Questions
1. **Remote Sync Backend REST API:** Since simulated real-time WebSocket emission is defined as a console-logged JSON payload, is there a requirement for a real REST HTTP backend API for the synchronization of the `SyncOutbox` payloads, or is outbox synchronization also simulated?
2. **GPS Polling Interval:** What is the desired periodic GPS capturing interval in seconds/minutes, and is there a distance filter threshold (in meters) to prevent capturing redundant points when stationary?
3. **Admin Dashboard Entry Point:** How and where in the main user interface should the Admin Dashboard be accessed (e.g., a tab bar, navigation drawer, or an icon in the AppBar)?
4. **Unit of Distance:** Should the total distance traveled metric display in kilometers, meters, or miles?
5. **Background Service Library:** Is there a preferred package for running background services in Flutter (e.g., `flutter_background_service`, `workmanager`, or native platform channels), or is it left to the developer's discretion?
6. **Mapbox Public Token Storage:** How should the Mapbox Access Token be injected and stored securely in the codebase to prevent leaking secret keys in open repositories?
