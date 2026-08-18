import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/incident_report.dart';
import '../../domain/models/location_point.dart';
import '../cubits/map/map_state.dart';
import 'map_status_card.dart';

/// Interactive Mapbox canvas widget displaying route points, hazard markers, and status card.
class MapCanvas extends StatefulWidget {
  final MapboxMap? mapboxMap;
  final ValueChanged<MapboxMap> onMapCreated;
  final int pointsCount;
  final double? currentLat;
  final double? currentLng;
  final List<LocationPoint> locationPoints;
  final List<IncidentReport> incidents;
  final CameraFocusTarget? cameraFocusTarget;

  const MapCanvas({
    super.key,
    this.mapboxMap,
    required this.onMapCreated,
    required this.pointsCount,
    this.currentLat,
    this.currentLng,
    this.locationPoints = const [],
    this.incidents = const [],
    this.cameraFocusTarget,
  });

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  PolylineAnnotationManager? _polylineManager;
  CircleAnnotationManager? _incidentManager;

  @override
  void didUpdateWidget(MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapboxMap != null) {
      if (oldWidget.locationPoints != widget.locationPoints && _polylineManager != null) {
        _renderRoutePolyline();
      }
      if (oldWidget.incidents != widget.incidents && _incidentManager != null) {
        _renderIncidentMarkers();
      }
      if (widget.cameraFocusTarget != null && widget.cameraFocusTarget != oldWidget.cameraFocusTarget) {
        _flyToCameraFocusTarget(widget.cameraFocusTarget!);
      }
    }
  }

  Future<void> _flyToCameraFocusTarget(CameraFocusTarget target) async {
    if (widget.mapboxMap == null) return;
    try {
      await widget.mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(target.longitude, target.latitude),
          ),
          zoom: target.zoom,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (_) {}
  }

  Future<void> _handleMapCreated(MapboxMap mapboxMap) async {
    widget.onMapCreated(mapboxMap);
    try {
      await mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          puckBearingEnabled: true,
          locationPuck: LocationPuck(
            locationPuck2D: DefaultLocationPuck2D(),
          ),
        ),
      );
      _polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
      _incidentManager = await mapboxMap.annotations.createCircleAnnotationManager();
      await _renderRoutePolyline();
      await _renderIncidentMarkers();
    } catch (_) {}
  }

  Future<void> _renderRoutePolyline() async {
    if (_polylineManager == null || widget.locationPoints.length < 2) return;
    try {
      await _polylineManager!.deleteAll();
      final coordinates = widget.locationPoints
          .map((p) => Position(p.longitude, p.latitude))
          .toList();
      await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: coordinates),
          lineColor: Colors.blue.toARGB32(),
          lineWidth: 4.0,
        ),
      );
    } catch (_) {}
  }

  Future<void> _renderIncidentMarkers() async {
    if (_incidentManager == null) return;
    try {
      await _incidentManager!.deleteAll();
      if (widget.incidents.isEmpty) return;

      final options = widget.incidents.map((incident) {
        int color;
        switch (incident.type) {
          case IncidentType.police:
            color = Colors.blue.toARGB32();
          case IncidentType.accident:
            color = Colors.red.toARGB32();
          case IncidentType.trafficHeavy:
            color = Colors.orange.toARGB32();
        }
        return CircleAnnotationOptions(
          geometry: Point(coordinates: Position(incident.longitude, incident.latitude)),
          circleRadius: 10.0,
          circleColor: color,
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.toARGB32(),
        );
      }).toList();

      await _incidentManager!.createMulti(options);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('mapbox_map_widget'),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          viewport: CameraViewportState(
            zoom: AppConstants.defaultZoom,
            center: Point(
              coordinates: Position(
                widget.currentLng ?? AppConstants.defaultLongitude,
                widget.currentLat ?? AppConstants.defaultLatitude,
              ),
            ),
          ),
          onMapCreated: _handleMapCreated,
        ),
        Positioned(
          bottom: AppSpacing.lg,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: MapStatusCard(
            pointsCount: widget.pointsCount,
            incidentsCount: widget.incidents.length,
            currentLat: widget.currentLat,
            currentLng: widget.currentLng,
          ),
        ),
      ],
    );
  }
}
