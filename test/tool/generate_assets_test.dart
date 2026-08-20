import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate high resolution app icon and splash logo PNG assets', () async {
    final iconBytes = await _generateAppIconBytes(512);
    final splashBytes = await _generateSplashLogoBytes(512);

    final iconFile = File('assets/images/app_icon.png');
    final splashFile = File('assets/images/splash_logo.png');

    await iconFile.writeAsBytes(iconBytes);
    await splashFile.writeAsBytes(splashBytes);

    expect(iconFile.existsSync(), isTrue);
    expect(splashFile.existsSync(), isTrue);
    expect(iconFile.lengthSync(), greaterThan(1000));
    expect(splashFile.lengthSync(), greaterThan(1000));
  });
}

Future<List<int>> _generateAppIconBytes(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
  final center = Offset(size / 2, size / 2);

  // Background Gradient Paint
  final bgRect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  final bgPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(size.toDouble(), size.toDouble()),
      [const Color(0xFF16082B), const Color(0xFF3C1361), const Color(0xFF52188A)],
      [0.0, 0.5, 1.0],
    );
  final RRect roundedBg = RRect.fromRectAndRadius(bgRect, Radius.circular(size * 0.22));
  canvas.drawRRect(roundedBg, bgPaint);

  // Outer Glowing Radar Rings
  final ringPaint1 = Paint()
    ..color = const Color(0x3300E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.015;
  canvas.drawCircle(center, size * 0.38, ringPaint1);

  final ringPaint2 = Paint()
    ..color = const Color(0x55B388FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.02;
  canvas.drawCircle(center, size * 0.28, ringPaint2);

  // GPS Route Breadcrumbs Curve
  final path = Path();
  path.moveTo(size * 0.2, size * 0.75);
  path.quadraticBezierTo(size * 0.35, size * 0.85, size * 0.5, size * 0.7);
  path.quadraticBezierTo(size * 0.65, size * 0.55, size * 0.8, size * 0.6);

  final routePaint = Paint()
    ..color = const Color(0x9900E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.018
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(path, routePaint);

  // Breadcrumb Dots
  final dotPaint = Paint()..color = const Color(0xFF00E5FF);
  canvas.drawCircle(Offset(size * 0.2, size * 0.75), size * 0.02, dotPaint);
  canvas.drawCircle(Offset(size * 0.5, size * 0.7), size * 0.02, dotPaint);
  canvas.drawCircle(Offset(size * 0.8, size * 0.6), size * 0.02, dotPaint);

  // Location Pin Gradient
  final pinCenter = Offset(size / 2, size * 0.42);
  final pinRadius = size * 0.18;

  final pinPath = Path();
  pinPath.addArc(Rect.fromCircle(center: pinCenter, radius: pinRadius), -3.14159, 3.14159);
  pinPath.lineTo(size / 2, size * 0.68);
  pinPath.close();

  final pinPaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset(size / 2, size * 0.24),
      Offset(size / 2, size * 0.68),
      [const Color(0xFF00E5FF), const Color(0xFF7C4DFF), const Color(0xFFD500F9)],
      [0.0, 0.5, 1.0],
    );

  // Shadow under pin
  final shadowPaint = Paint()
    ..color = const Color(0x66000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  canvas.drawCircle(Offset(size / 2, size * 0.69), size * 0.08, shadowPaint);

  canvas.drawPath(pinPath, pinPaint);

  // Pin Inner Hole / Lens
  final innerCirclePaint = Paint()..color = const Color(0xFFFFFFFF);
  canvas.drawCircle(pinCenter, size * 0.07, innerCirclePaint);

  final coreDotPaint = Paint()..color = const Color(0xFF651FFF);
  canvas.drawCircle(pinCenter, size * 0.035, coreDotPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<List<int>> _generateSplashLogoBytes(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
  final center = Offset(size / 2, size * 0.45);

  // Background - Dark purple gradient
  final bgRect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  final bgPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(size.toDouble(), size.toDouble()),
      [const Color(0xFF0D061A), const Color(0xFF1E0B36), const Color(0xFF2E004E)],
      [0.0, 0.5, 1.0],
    );
  canvas.drawRect(bgRect, bgPaint);

  // Outer Glowing Rings
  final ringPaint1 = Paint()
    ..color = const Color(0x3300E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.015;
  canvas.drawCircle(center, size * 0.32, ringPaint1);

  final ringPaint2 = Paint()
    ..color = const Color(0x55B388FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.018;
  canvas.drawCircle(center, size * 0.24, ringPaint2);

  // Pin
  final pinCenter = Offset(size / 2, size * 0.40);
  final pinRadius = size * 0.15;

  final pinPath = Path();
  pinPath.addArc(Rect.fromCircle(center: pinCenter, radius: pinRadius), -3.14159, 3.14159);
  pinPath.lineTo(size / 2, size * 0.62);
  pinPath.close();

  final pinPaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset(size / 2, size * 0.25),
      Offset(size / 2, size * 0.62),
      [const Color(0xFF00E5FF), const Color(0xFF7C4DFF), const Color(0xFFE040FB)],
      [0.0, 0.5, 1.0],
    );

  canvas.drawPath(pinPath, pinPaint);

  final innerCirclePaint = Paint()..color = const Color(0xFFFFFFFF);
  canvas.drawCircle(pinCenter, size * 0.06, innerCirclePaint);

  final coreDotPaint = Paint()..color = const Color(0xFF651FFF);
  canvas.drawCircle(pinCenter, size * 0.03, coreDotPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
