import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Reusable overlay button to trigger map camera recentering back to live user position.
class MyLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MyLocationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.myLocation,
      button: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: FloatingActionButton.small(
          heroTag: 'my_location_fab',
          onPressed: onPressed,
          tooltip: AppStrings.myLocation,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(
            Icons.my_location_rounded,
            size: 22,
          ),
        ),
      ),
    );
  }
}
