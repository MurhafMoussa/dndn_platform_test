import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.report_problem_rounded),
          SizedBox(width: 8),
          Text('Report Incident'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionTile(
            context,
            type: IncidentType.police,
            title: 'Police',
            subtitle: 'Speed check or police presence',
            icon: Icons.local_police_rounded,
            iconColor: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            context,
            type: IncidentType.accident,
            title: 'Accident',
            subtitle: 'Vehicle collision or road hazard',
            icon: Icons.car_crash_rounded,
            iconColor: colorScheme.error,
          ),
          const SizedBox(height: 8),
          _buildOptionTile(
            context,
            type: IncidentType.trafficHeavy,
            title: 'Traffic Heavy',
            subtitle: 'Severe traffic congestion or delay',
            icon: Icons.traffic_rounded,
            iconColor: Colors.orange,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop();
            onSelectIncident(type);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                const SizedBox(width: 16),
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
