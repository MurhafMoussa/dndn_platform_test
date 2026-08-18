import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/incident_report.dart';

/// Scrollable Data Table displaying itemized log of submitted incident reports.
class IncidentsTable extends StatelessWidget {
  /// Chronological list of incident reports.
  final List<IncidentReport> incidents;

  /// Optional callback invoked when the user taps "View on Map" for an incident.
  final void Function(double latitude, double longitude)? onViewOnMap;

  const IncidentsTable({
    super.key,
    required this.incidents,
    this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (incidents.isEmpty) {
      return Container(
        padding: AppSpacing.paddingXl,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.noIncidentsLogged,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.noIncidentsSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: 'Submitted incident reports table',
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            columns: const [
              DataColumn(label: Text(AppStrings.colType)),
              DataColumn(label: Text(AppStrings.colTimestamp)),
              DataColumn(label: Text(AppStrings.colLatitude)),
              DataColumn(label: Text(AppStrings.colLongitude)),
              DataColumn(label: Text('')),
            ],
            rows: incidents.map((incident) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIncidentIcon(incident.type),
                          size: 18,
                          color: _getIncidentColor(incident.type, colorScheme),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(_getIncidentTitle(incident.type)),
                      ],
                    ),
                  ),
                  DataCell(Text(_formatTimestamp(incident.timestamp))),
                  DataCell(Text(incident.latitude.toStringAsFixed(4))),
                  DataCell(Text(incident.longitude.toStringAsFixed(4))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.location_on_outlined, size: 20),
                      tooltip: AppStrings.viewOnMap,
                      onPressed: onViewOnMap != null
                          ? () => onViewOnMap!(incident.latitude, incident.longitude)
                          : null,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.police:
        return Icons.local_police_rounded;
      case IncidentType.accident:
        return Icons.car_crash_rounded;
      case IncidentType.trafficHeavy:
        return Icons.traffic_rounded;
    }
  }

  static Color _getIncidentColor(IncidentType type, ColorScheme scheme) {
    switch (type) {
      case IncidentType.police:
        return AppColors.policeColor;
      case IncidentType.accident:
        return AppColors.accidentColor;
      case IncidentType.trafficHeavy:
        return AppColors.trafficColor;
    }
  }

  static String _getIncidentTitle(IncidentType type) {
    switch (type) {
      case IncidentType.police:
        return AppStrings.policeTitle;
      case IncidentType.accident:
        return AppStrings.accidentTitle;
      case IncidentType.trafficHeavy:
        return AppStrings.trafficHeavyTitle;
    }
  }

  static String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }
}
