import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/models/incident_report.dart';

/// Utility class to programmatically generate sharp custom icon PNG markers for incident types.
abstract final class IncidentIconHelper {
  static final Map<IncidentType, Uint8List> _cache = {};

  /// Returns cached PNG bytes or generates a new 80x80 custom icon PNG for the given incident type.
  static Future<Uint8List> getIconBytes(IncidentType type) async {
    if (_cache.containsKey(type)) {
      return _cache[type]!;
    }

    final bytes = await _generateIconPng(type);
    _cache[type] = bytes;
    return bytes;
  }

  static Future<Uint8List> _generateIconPng(IncidentType type) async {
    const double size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final (Color bgColor, IconData iconData) = switch (type) {
      IncidentType.police => (
          const Color(0xFF1E88E5),
          Icons.local_police_rounded,
        ),
      IncidentType.accident => (
          const Color(0xFFE53935),
          Icons.car_crash_rounded,
        ),
      IncidentType.trafficHeavy => (
          const Color(0xFFFB8C00),
          Icons.traffic_rounded,
        ),
    };

    // Outer shadow circle
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 2), size / 2 - 8, shadowPaint);

    // Main background circle
    final bgPaint = Paint()..color = bgColor;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 8, bgPaint);

    // White border ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 8, borderPaint);

    // Icon glyph
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 42,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
