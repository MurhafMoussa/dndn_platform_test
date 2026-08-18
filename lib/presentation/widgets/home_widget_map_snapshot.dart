import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/incident_report.dart';
import '../../domain/models/location_point.dart';

/// Offscreen canvas painter that renders a styled map snapshot image with polyline route, hazard markers, and user avatar puck.
abstract final class HomeWidgetMapSnapshot {
  /// Generates a 600x400 PNG image bytes representing the GPS breadcrumb route and incident markers.
  static Future<Uint8List> generateSnapshotBytes({
    required List<LocationPoint> points,
    List<IncidentReport> incidents = const [],
    double width = 600.0,
    double height = 400.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Dark satellite map style background
    final bgPaint = Paint()..color = const Color(0xFF141D2B);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Subtle map grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    for (double x = 0; x < width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    ui.Image? avatarImage;
    try {
      final byteData = await rootBundle.load('assets/images/user_puck.png');
      final codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
        targetWidth: 54,
        targetHeight: 54,
      );
      final frame = await codec.getNextFrame();
      avatarImage = frame.image;
    } catch (_) {}

    if (points.isNotEmpty) {
      _paintRouteAndMarkers(
        canvas: canvas,
        points: points,
        incidents: incidents,
        avatarImage: avatarImage,
        width: width,
        height: height,
      );
    } else {
      _paintEmptyState(canvas, width, height);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _paintRouteAndMarkers({
    required Canvas canvas,
    required List<LocationPoint> points,
    required List<IncidentReport> incidents,
    required ui.Image? avatarImage,
    required double width,
    required double height,
  }) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    // Add padding around coordinates
    final latPadding = max((maxLat - minLat) * 0.2, 0.001);
    final lngPadding = max((maxLng - minLng) * 0.2, 0.001);
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    Offset toOffset(double lat, double lng) {
      final x = ((lng - minLng) / (maxLng - minLng)) * (width - 80) + 40;
      final y = height - (((lat - minLat) / (maxLat - minLat)) * (height - 80) + 40);
      return Offset(x, y);
    }

    // Route line glow effect
    if (points.length >= 2) {
      final path = Path();
      final firstOffset = toOffset(points.first.latitude, points.first.longitude);
      path.moveTo(firstOffset.dx, firstOffset.dy);

      for (int i = 1; i < points.length; i++) {
        final offset = toOffset(points[i].latitude, points[i].longitude);
        path.lineTo(offset.dx, offset.dy);
      }

      final glowPaint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glowPaint);

      final linePaint = Paint()
        ..color = const Color(0xFF64B5F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      // Green Start dot
      canvas.drawCircle(firstOffset, 7.0, Paint()..color = const Color(0xFF4CAF50));
      canvas.drawCircle(firstOffset, 4.0, Paint()..color = Colors.white);
    }

    // Render incident markers along route
    for (final incident in incidents) {
      final offset = toOffset(incident.latitude, incident.longitude);
      final color = switch (incident.type) {
        IncidentType.police => const Color(0xFF1E88E5),
        IncidentType.accident => const Color(0xFFE53935),
        IncidentType.trafficHeavy => const Color(0xFFFB8C00),
      };

      canvas.drawCircle(offset, 9.0, Paint()..color = color);
      canvas.drawCircle(
        offset,
        9.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Latest user position puck: Personal Avatar Photo or Blue Puck fallback
    final lastPoint = points.last;
    final currentOffset = toOffset(lastPoint.latitude, lastPoint.longitude);

    if (avatarImage != null) {
      const radius = 18.0;

      // Drop shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(currentOffset.dx, currentOffset.dy + 2), radius, shadowPaint);

      // Clip circular avatar image
      canvas.save();
      final clipPath = Path()..addOval(Rect.fromCircle(center: currentOffset, radius: radius));
      canvas.clipPath(clipPath);

      final srcRect = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
      final dstRect = Rect.fromCircle(center: currentOffset, radius: radius);
      canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint()..filterQuality = ui.FilterQuality.high);
      canvas.restore();

      // White border ring
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(currentOffset, radius, borderPaint);
    } else {
      // Fallback location puck
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(currentOffset.dx, currentOffset.dy + 2), 12.0, shadowPaint);

      canvas.drawCircle(currentOffset, 12.0, Paint()..color = const Color(0xFF1976D2));
      canvas.drawCircle(
        currentOffset,
        12.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
      canvas.drawCircle(currentOffset, 5.0, Paint()..color = const Color(0xFFBBDEFB));
    }
  }

  static void _paintEmptyState(Canvas canvas, double width, double height) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: 'GPS Route Map Tracking',
      style: TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(width / 2 - textPainter.width / 2, height / 2 - textPainter.height / 2),
    );
  }
}
