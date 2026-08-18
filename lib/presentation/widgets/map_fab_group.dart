import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import 'my_location_button.dart';

/// Floating action button group for map view: location recentering and hazard incident reporting.
class MapFabGroup extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback onReportHazard;

  const MapFabGroup({
    super.key,
    required this.onRecenter,
    required this.onReportHazard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MyLocationButton(onPressed: onRecenter),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: 'Report hazard incident button',
          button: true,
          child: FloatingActionButton.extended(
            heroTag: 'fab_report_hazard',
            onPressed: onReportHazard,
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text(AppStrings.reportHazard),
          ),
        ),
      ],
    );
  }
}
