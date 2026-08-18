import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dndn_platform_test/core/constants/app_strings.dart';
import 'package:dndn_platform_test/presentation/widgets/my_location_button.dart';

void main() {
  group('MyLocationButton', () {
    testWidgets('renders my location button with icon and tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyLocationButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(MyLocationButton), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byTooltip(AppStrings.myLocation), findsOneWidget);
    });

    testWidgets('invokes onPressed callback when tapped', (WidgetTester tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyLocationButton(
              onPressed: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MyLocationButton));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });
  });
}
