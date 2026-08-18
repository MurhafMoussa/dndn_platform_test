/// Centralized UI string constants for clear, concise product copy.
abstract final class AppStrings {
  // Navigation & Drawer
  static const String navHeaderTitle = 'Location & Telemetry';
  static const String navHeaderSubtitle = 'Offline-First Tracking Platform';
  static const String navMapLabel = 'Map & Tracking';
  static const String navAdminLabel = 'Admin Dashboard';
  static const String userSession = 'User Session';
  static const String adminSession = 'Admin Session';

  // Map View
  static const String mapTitle = 'Map & Live Tracking';
  static const String pauseTracking = 'Pause Tracking';
  static const String startTracking = 'Start Tracking';
  static const String reportHazard = 'Report Hazard';
  static const String viewOnMap = 'View on Map';
  static const String myLocation = 'My Location';
  static const String backgroundTrackingActive = 'Background Tracking Active';
  static const String locationHistoryLoading = 'Loading location history...';
  static const String locationFailureTitle = 'Location Service Failure';
  static const String retry = 'Retry';
  static const String mapCanvasTitle = 'Interactive Map View';
  static const String gpsBreadcrumbsTitle = 'GPS Route Breadcrumbs';
  static const String gpsBreadcrumbsExplanationTitle = 'What are GPS Breadcrumbs?';
  static const String gpsBreadcrumbsExplanationBody =
      'GPS Breadcrumbs are coordinate snapshots recorded along your path. They are saved locally on your device to render your movement route on the map, compute total distance, and sync when online.';
  static const String waypointsLabel = 'Tracked GPS Waypoints';
  static const String hazardsOnMap = 'Reported Hazards on Map';
  static const String ok = 'OK';

  // Incident Dialog
  static const String reportIncidentTitle = 'Report Incident';
  static const String policeTitle = 'Police';
  static const String policeSubtitle = 'Speed check or police presence';
  static const String accidentTitle = 'Accident';
  static const String accidentSubtitle = 'Vehicle collision or road hazard';
  static const String trafficHeavyTitle = 'Traffic Heavy';
  static const String trafficHeavySubtitle = 'Severe traffic congestion or delay';
  static const String cancel = 'Cancel';

  // Admin View
  static const String adminTitle = 'Admin Telemetry Dashboard';
  static const String telemetryOverview = 'Telemetry Overview';
  static const String totalDistance = 'Total Distance Traveled';
  static const String totalPoints = 'Total Location Points';
  static const String telemetryExplanationsTitle = 'Telemetry Metrics Explanation';
  static const String telemetryExplanationsBody =
      'Total Location Points represent discrete GPS fixes recorded locally. Total Distance is calculated using geodesic paths between consecutive coordinates.';
  static const String incidentReportsLog = 'Incident Reports Log';
  static const String noIncidentsLogged = 'No Incident Reports Logged';
  static const String noIncidentsSubtitle = 'Submitted reports will appear in this telemetry table.';
  static const String computingTelemetry = 'Computing telemetry metrics...';
  static const String telemetryErrorTitle = 'Telemetry Error';

  // Table Headers
  static const String colType = 'Type';
  static const String colTimestamp = 'Timestamp';
  static const String colLatitude = 'Latitude';
  static const String colLongitude = 'Longitude';

  // Unauthorized View
  static const String accessRestricted = 'Access Restricted';
  static const String unauthorizedAccess = 'Unauthorized Access';
  static const String unauthorizedBody =
      'The Telemetry Dashboard is restricted to administrator sessions. Switch to Administrator Mode to gain access.';
  static const String switchToAdmin = 'Switch to Administrator Mode';
  static const String returnToMap = 'Return to Map View';
}
