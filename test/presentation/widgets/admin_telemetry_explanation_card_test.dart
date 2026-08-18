import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dndn_platform_test/core/constants/app_strings.dart';
import 'package:dndn_platform_test/presentation/widgets/admin_telemetry_explanation_card.dart';

void main() {
  group('AdminTelemetryExplanationCard', () {
    testWidgets('renders telemetry metric explanations on mobile view (<600dp)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(380, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminTelemetryExplanationCard(),
          ),
        ),
      );

      expect(find.byType(AdminTelemetryExplanationCard), findsOneWidget);
      expect(find.text(AppStrings.telemetryExplanationsTitle), findsOneWidget);
      expect(find.text(AppStrings.totalPoints), findsOneWidget);
      expect(find.text(AppStrings.totalDistance), findsOneWidget);
    });

    testWidgets('renders telemetry metric explanations side-by-side on tablet view (>=600dp)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminTelemetryExplanationCard(),
          ),
        ),
      );

      expect(find.byType(AdminTelemetryExplanationCard), findsOneWidget);
      expect(find.text(AppStrings.telemetryExplanationsTitle), findsOneWidget);
      expect(find.text(AppStrings.totalPoints), findsOneWidget);
      expect(find.text(AppStrings.totalDistance), findsOneWidget);
    });
  });
}
