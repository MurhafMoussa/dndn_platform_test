import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/incident_report.dart';

/// Modal choices dialog for reporting hazard incidents (Police, Accident, Traffic Heavy).
class IncidentReportDialog extends StatelessWidget {
  /// Callback invoked when user selects an incident option.
  final ValueChanged<IncidentType> onSelectIncident;

  const IncidentReportDialog({
    super.key,
    required this.onSelectIncident,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.report_problem_rounded),
          SizedBox(width: AppSpacing.sm),
          Text(AppStrings.reportIncidentTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionTile(
            context,
            type: IncidentType.police,
            title: AppStrings.policeTitle,
            subtitle: AppStrings.policeSubtitle,
            icon: Icons.local_police_rounded,
            iconColor: AppColors.policeColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildOptionTile(
            context,
            type: IncidentType.accident,
            title: AppStrings.accidentTitle,
            subtitle: AppStrings.accidentSubtitle,
            icon: Icons.car_crash_rounded,
            iconColor: AppColors.accidentColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildOptionTile(
            context,
            type: IncidentType.trafficHeavy,
            title: AppStrings.trafficHeavyTitle,
            subtitle: AppStrings.trafficHeavySubtitle,
            icon: Icons.traffic_rounded,
            iconColor: AppColors.trafficColor,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IncidentType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Semantics(
      label: 'Report $title incident',
      button: true,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: AppRadii.borderMd,
        child: InkWell(
          borderRadius: AppRadii.borderMd,
          onTap: () {
            Navigator.of(context).pop();
            onSelectIncident(type);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
