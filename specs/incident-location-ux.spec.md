# Feature Specification: Initial Location, Real-Time Incident Markers, and Navigation UX

## 1. Problem
Field testing on physical devices revealed several UX and operational issues:
1. Upon application launch, the map does not prompt for location permission or center on the user's live position immediately, causing an initial camera offset before tracking starts.
2. Reported incidents are saved to local persistence but fail to render as visible markers on the Mapbox canvas immediately after submission.
3. Educational/explanatory UI card elements regarding "GPS Breadcrumbs" on the primary map screen clutter the live view; explanations belong in the Admin Telemetry Dashboard (`/admin`) while maintaining screen responsiveness.
4. When inspecting incident reports in the telemetry log, administrators and users cannot tap an incident card to inspect its exact location on the interactive map.
5. Once a user pans or zooms away to inspect a distant incident, there is no quick action to re-center the map view back to their current live location.

## 2. User Stories
* **US-1 (Initial Live Location & Permission on Launch):** As a user, I want the application to request location permissions and center the map on my live location as soon as the app opens so that I am immediately oriented on the map.
* **US-2 (Immediate Incident Visualization):** As a user, I want reported incidents (Police, Accident, Traffic Heavy) to appear on the map canvas as visible markers immediately after I submit them.
* **US-3 (Admin Telemetry Clarification & Responsive Layout):** As an administrator, I want explanations for telemetry metrics (location points, distance calculations) placed in the Admin Telemetry Dashboard rather than the main map screen, rendered responsively across screen sizes.
* **US-4 (Focus Incident on Map):** As a user or admin viewing an incident report card, I want a "View on Map" button that moves the map camera directly to that incident's coordinates.
* **US-5 (Recenter to My Location):** As a user inspecting a distant incident or panned map region, I want a "My Location" button on the map view that smoothly re-centers the map camera back to my live position.

## 3. Functional Requirements
* **FR-1 Immediate Location Permission & Position Fix:**
  * FR-1.1: Trigger location permission check and request on application startup / map initialization.
  * FR-1.2: Acquire initial GPS position fix on launch and set the Mapbox camera center to the user's coordinates.
* **FR-2 Real-Time Incident Map Overlay:**
  * FR-2.1: Observe the incident repository stream reactively on the map screen.
  * FR-2.2: Render point or circle annotations for each incident report on the Mapbox map immediately upon creation.
  * FR-2.3: Use distinct visual indicators corresponding to incident types (Police, Accident, Traffic Heavy).
* **FR-3 Clean Map Screen & Admin Telemetry Explanations:**
  * FR-3.1: Remove the breadcrumb explanation card/dialog from the primary map canvas.
  * FR-3.2: Add telemetry metric explanations and tooltips exclusively within the Admin Telemetry Dashboard (`/admin`).
  * FR-3.3: Ensure the Admin Telemetry Dashboard layout adapts responsively to mobile and tablet screen widths.
* **FR-4 Focus Incident on Map:**
  * FR-4.1: Add a "View on Map" button/action to each incident report card in the incident log.
  * FR-4.2: Tapping "View on Map" navigates to the map screen and animates (`flyTo` / `setCamera`) the Mapbox camera to the incident's latitude and longitude coordinates.
* **FR-5 My Location Recenter Action:**
  * FR-5.1: Provide a dedicated "My Location" action button on the primary map screen overlay.
  * FR-5.2: Tapping "My Location" triggers a camera transition (`flyTo` or `easeTo`) back to the user's current GPS position.

## 4. UI/UX Requirements
* **UI-1 Initial Map Camera:**
  * Center on user's live GPS coordinates immediately after permission grant.
* **UI-2 Incident Markers on Canvas:**
  * Display color-coded incident markers (Police = Blue, Accident = Red, Traffic Heavy = Orange) on the Mapbox layer.
* **UI-3 Admin Telemetry Screen (`/admin`):**
  * Include metric helper tooltips or explanatory text for "Total Location Points" and "Total Distance Traveled".
  * Maintain responsive grid/column layout using Material breakpoints or `LayoutBuilder`.
* **UI-4 Incident Card Navigation Action:**
  * Each incident card displays an elevated or icon button labeled "View on Map" with a map pin icon.
* **UI-5 Recenter Floating Action / Button:**
  * Position a "My Location" icon button or mini-FAB on the map screen (e.g. above or alongside map controls).

## 5. Non-Functional Requirements
* **NFR-1 MVVM Architectural Direction:**
  * Maintain strict separation: View -> ViewModel/Cubit -> Repository -> Data Source.
  * Navigation triggers from incident cards to map coordinates must pass coordinate parameters through the app router or map presentation state.
* **NFR-2 Performance & Responsiveness:**
  * Map camera animations (`flyTo`) must execute smoothly without freezing the UI thread.
  * Incident marker updates must happen reactively without full map widget re-creations.
* **NFR-3 Responsiveness:**
  * UI components must adjust layout dynamically for screen widths ranging from small mobile phones (360dp) to tablets (600dp+).

## 6. Data Requirements
* **Domain Models:**
  * `IncidentReport`: `id`, `type`, `latitude`, `longitude`, `timestamp`.
  * `LocationPoint`: `id`, `latitude`, `longitude`, `timestamp`.
* **Navigation Parameters:**
  * Route parameter or state payload for target camera focus: `double targetLat`, `double targetLng`, `double? zoom`.

## 7. Offline-First Behavior
* **Local Incident Retrieval:** Incidents created while offline are stored locally in the Drift database and rendered as markers on the map canvas immediately, without requiring network connectivity.
* **Camera Navigation Offline:** Viewing incidents on the map and recentering to live GPS position operate fully offline using locally cached map tiles and local device GPS hardware.

## 8. Failure Scenarios
* **Location Permission Denied on Launch:** If the user denies location permission at startup, present the location failure banner with a "Retry" or "Open Location Settings" button, retaining Syria fallback coordinates until permission is granted.
* **GPS Fix Unavailable:** If location permission is granted but GPS satellite fix is delayed, show loading state or retain fallback coordinates until first location fix is received.
* **Navigating to Incident with Invalid Coordinates:** If an incident has invalid coordinates (outside valid lat/lng bounds), log error and prevent camera jump.

## 9. Acceptance Criteria
* **AC-1:** On app launch, the app prompts for location permissions and centers the map camera on the user's current GPS position.
* **AC-2:** Submitting a new incident report immediately displays a visible marker on the Mapbox map at the incident location.
* **AC-3:** Map screen displays clean canvas without breadcrumb explanation popups; telemetry explanations are presented responsively in the Admin Dashboard (`/admin`).
* **AC-4:** Tapping "View on Map" on an incident report card navigates to the map screen and centers the camera on that incident's coordinates.
* **AC-5:** Tapping the "My Location" button on the map screen smoothly re-centers the camera on the user's live location.

## 10. Testing Requirements
* **Unit Tests:**
  * `MapCubit`: Test initial location acquisition on start, incident stream subscription updates, camera focus target state, and recenter triggers.
* **Widget Tests:**
  * "My Location" button rendering and tap callback.
  * Incident card "View on Map" button rendering and navigation invocation.
  * Admin Telemetry Dashboard responsive layout and explanation tooltips.
* **Integration Tests:**
  * End-to-end flow: Submit incident -> verify immediate marker emission -> navigate via incident card -> verify camera focus -> tap "My Location" -> verify camera recenter.

## 11. Open Questions
1. **Camera Zoom Level for Incident Focus**: Should focusing on an incident use the default zoom level (14.0) or a tighter zoom (16.0)? *(Defaulting to 16.0 for detailed hazard context unless specified otherwise).*
2. **Incident Selection Banner on Map**: When navigating to an incident on the map via "View on Map", should an info card/banner display details about that specific selected incident on the map screen? *(Can display a transient SnackBar or banner with incident type and timestamp).*
