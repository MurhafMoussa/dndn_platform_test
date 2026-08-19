import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/incident_report.dart';
import '../../domain/models/location_point.dart';
import '../cubits/map/map_cubit.dart';
import '../cubits/map/map_state.dart';
import 'incident_icon_helper.dart';

/// Interactive Mapbox canvas widget displaying route points, custom hazard icon markers, and user location puck.
class MapCanvas extends StatefulWidget {
  final MapboxMap? mapboxMap;
  final ValueChanged<MapboxMap> onMapCreated;
  final int pointsCount;
  final double? currentLat;
  final double? currentLng;
  final List<LocationPoint> locationPoints;
  final List<IncidentReport> incidents;
  final CameraFocusTarget? cameraFocusTarget;
  final double savedZoom;

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
    this.savedZoom = 14.0,
  });

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  MapboxMap? _mapInstance;
  PolylineAnnotationManager? _polylineManager;
  PointAnnotationManager? _incidentPointManager;
  late final CameraViewportState _initialViewport;

  @override
  void initState() {
    super.initState();
    final initialZoom = widget.cameraFocusTarget?.zoom ?? widget.savedZoom;
    final initialLat = widget.cameraFocusTarget?.latitude ?? widget.currentLat ?? AppConstants.defaultLatitude;
    final initialLng = widget.cameraFocusTarget?.longitude ?? widget.currentLng ?? AppConstants.defaultLongitude;

    _initialViewport = CameraViewportState(
      zoom: initialZoom,
      center: Point(
        coordinates: Position(initialLng, initialLat),
      ),
    );
  }

  @override
  void didUpdateWidget(MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final map = _mapInstance ?? widget.mapboxMap;
    if (map == null) return;

    if (_shouldUpdatePolyline(oldWidget)) {
      _renderRoutePolyline();
    }
    if (_shouldUpdateIncidents(oldWidget)) {
      _renderIncidentMarkers();
    }
    if (widget.cameraFocusTarget != null && widget.cameraFocusTarget != oldWidget.cameraFocusTarget) {
      _flyToCameraFocusTarget(widget.cameraFocusTarget!, map: map);
    } else if (widget.cameraFocusTarget != null && oldWidget.mapboxMap == null && widget.mapboxMap != null) {
      _flyToCameraFocusTarget(widget.cameraFocusTarget!, map: map);
    } else if (widget.cameraFocusTarget == null &&
        widget.currentLat != null &&
        widget.currentLng != null &&
        (oldWidget.currentLat == null || oldWidget.currentLng == null)) {
      _flyToCameraFocusTarget(
        CameraFocusTarget(latitude: widget.currentLat!, longitude: widget.currentLng!, zoom: widget.savedZoom),
        map: map,
      );
    }
  }

  bool _shouldUpdatePolyline(MapCanvas oldWidget) {
    return _polylineManager != null &&
        (oldWidget.locationPoints.length != widget.locationPoints.length ||
            oldWidget.locationPoints != widget.locationPoints);
  }

  bool _shouldUpdateIncidents(MapCanvas oldWidget) {
    return _incidentPointManager != null &&
        (oldWidget.incidents.length != widget.incidents.length ||
            oldWidget.incidents != widget.incidents);
  }

  Future<void> _flyToCameraFocusTarget(CameraFocusTarget target, {MapboxMap? map}) async {
    final mapbox = map ?? _mapInstance ?? widget.mapboxMap;
    if (mapbox == null) return;
    try {
      await mapbox.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(target.longitude, target.latitude)),
          zoom: target.zoom,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (_) {}
  }

  Future<void> _handleMapCreated(MapboxMap mapboxMap) async {
    _mapInstance = mapboxMap;
    widget.onMapCreated(mapboxMap);
    try {
      Uint8List? customPuckBytes;
      try {
        final byteData = await rootBundle.load('assets/images/user_puck.png');
        customPuckBytes = await _createCircularAvatarPuck(byteData.buffer.asUint8List(), size: 80.0);
      } catch (_) {}

      await mapboxMap.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          puckBearingEnabled: true,
          locationPuck: LocationPuck(
            locationPuck2D: customPuckBytes != null
                ? LocationPuck2D(topImage: customPuckBytes)
                : DefaultLocationPuck2D(),
          ),
        ),
      );
      _polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
      _incidentPointManager = await mapboxMap.annotations.createPointAnnotationManager();
      await _renderRoutePolyline();
      await _renderIncidentMarkers();

      final target = widget.cameraFocusTarget;
      if (target != null) {
        await _flyToCameraFocusTarget(target, map: mapboxMap);
      } else if (widget.currentLat != null && widget.currentLng != null) {
        await _flyToCameraFocusTarget(
          CameraFocusTarget(
            latitude: widget.currentLat!,
            longitude: widget.currentLng!,
            zoom: widget.savedZoom,
          ),
          map: mapboxMap,
        );
      }
    } catch (_) {}
  }

  Future<Uint8List> _createCircularAvatarPuck(Uint8List rawBytes, {double size = 80.0}) async {
    final codec = await ui.instantiateImageCodec(
      rawBytes,
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 6;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(center.dx, center.dy + 2), radius, shadowPaint);

    // Clip circular image
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawImageRect(image, srcRect, dstRect, Paint()..filterQuality = ui.FilterQuality.high);
    canvas.restore();

    // White border ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius, borderPaint);

    final picture = recorder.endRecording();
    final avatarImage = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await avatarImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _renderRoutePolyline() async {
    if (_polylineManager == null || widget.locationPoints.length < 2) return;
    try {
      await _polylineManager!.deleteAll();
      final coordinates = widget.locationPoints.map((p) => Position(p.longitude, p.latitude)).toList();
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
    if (_incidentPointManager == null) return;
    try {
      await _incidentPointManager!.deleteAll();
      if (widget.incidents.isEmpty) return;

      final options = <PointAnnotationOptions>[];
      for (final incident in widget.incidents) {
        final iconBytes = await IncidentIconHelper.getIconBytes(incident.type);
        options.add(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(incident.longitude, incident.latitude)),
            image: iconBytes,
            iconSize: 0.8,
          ),
        );
      }

      await _incidentPointManager!.createMulti(options);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('mapbox_map_widget'),
      styleUri: MapboxStyles.SATELLITE_STREETS,
      viewport: _initialViewport,
      textureView: false,
      onMapCreated: _handleMapCreated,
      onCameraChangeListener: (data) {
        context.read<MapCubit>().saveZoomLevel(data.cameraState.zoom);
      },
    );
  }
}
