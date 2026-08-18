import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/failures/tracking_failure.dart';
import '../../domain/models/location_point.dart';
import '../cubits/incident/incident_cubit.dart';
import '../cubits/incident/incident_state.dart';
import '../cubits/map/map_cubit.dart';
import '../cubits/map/map_state.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/incident_report_dialog.dart';
import '../widgets/map_canvas.dart';
import '../widgets/map_tracking_status_banner.dart';
import '../widgets/my_location_button.dart';

/// Screen displaying interactive live map, traveled polyline route, and incident reporting FAB.
class MapView extends StatefulWidget {
  final double? targetLat;
  final double? targetLng;

  const MapView({
    super.key,
    this.targetLat,
    this.targetLng,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // ignore: unused_field
  MapboxMap? _mapboxMap;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(AppConstants.defaultMapboxToken);
    final mapCubit = context.read<MapCubit>();
    if (mapCubit.state is MapInitial) {
      mapCubit.initializeMap().then((_) {
        if (mounted && widget.targetLat != null && widget.targetLng != null) {
          mapCubit.focusLocation(widget.targetLat!, widget.targetLng!);
        }
      });
    } else {
      if (widget.targetLat != null && widget.targetLng != null) {
        mapCubit.focusLocation(widget.targetLat!, widget.targetLng!);
      }
    }
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.targetLat != oldWidget.targetLat || widget.targetLng != oldWidget.targetLng) &&
        widget.targetLat != null &&
        widget.targetLng != null) {
      context.read<MapCubit>().focusLocation(widget.targetLat!, widget.targetLng!);
    }
  }

  void _showReportIncidentDialog(BuildContext context, LocationPoint? currentLocation) {
    final lat = currentLocation?.latitude ?? AppConstants.defaultLatitude;
    final lng = currentLocation?.longitude ?? AppConstants.defaultLongitude;

    showDialog<void>(
      context: context,
      builder: (_) {
        return IncidentReportDialog(
          onSelectIncident: (type) {
            context.read<IncidentCubit>().submitIncident(
                  type: type,
                  latitude: lat,
                  longitude: lng,
                );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<IncidentCubit, IncidentState>(
      listener: (context, incidentState) {
        if (incidentState is IncidentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Incident reported: ${incidentState.report.type.name}'),
              backgroundColor: colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (incidentState is IncidentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to report incident: ${incidentState.failure.message}'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.mapTitle),
          actions: [
            BlocBuilder<MapCubit, MapState>(
              builder: (context, state) {
                if (state is! MapLoaded) return const SizedBox.shrink();
                final isTracking = state.isTracking;
                return IconButton(
                  icon: Icon(
                    isTracking ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: isTracking ? colorScheme.primary : colorScheme.onSurface,
                  ),
                  tooltip: isTracking ? AppStrings.pauseTracking : AppStrings.startTracking,
                  onPressed: () {
                    final cubit = context.read<MapCubit>();
                    isTracking ? cubit.stopTracking() : cubit.startTracking();
                  },
                );
              },
            ),
          ],
        ),
        drawer: const AppNavigationDrawer(currentRoute: AppConstants.mapRoute),
        body: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            if (state is MapLoading || state is MapInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MapFailure) {
              final isServiceDisabled = state.failure is LocationServiceDisabledFailure ||
                  state.failure.message.contains('disabled');
              return Center(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_rounded, size: 48, color: colorScheme.error),
                      const SizedBox(height: AppSpacing.lg),
                      Text(AppStrings.locationFailureTitle),
                      const SizedBox(height: AppSpacing.sm),
                      Text(state.failure.message, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.xl),
                      if (isServiceDisabled) ...[
                        ElevatedButton.icon(
                          onPressed: () => context.read<MapCubit>().openLocationSettings(),
                          icon: const Icon(Icons.settings_rounded),
                          label: const Text('Open Location Settings'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => context.read<MapCubit>().initializeMap(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is MapLoaded) {
              return Stack(
                children: [
                  MapCanvas(
                    mapboxMap: _mapboxMap,
                    onMapCreated: (map) => _mapboxMap = map,
                    pointsCount: state.locationPoints.length,
                    currentLat: state.currentLocation?.latitude,
                    currentLng: state.currentLocation?.longitude,
                    locationPoints: state.locationPoints,
                    incidents: state.incidents,
                    cameraFocusTarget: state.cameraFocusTarget,
                  ),
                  if (state.isTracking) const MapTrackingStatusBanner(),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: BlocBuilder<MapCubit, MapState>(
          builder: (context, state) {
            final loc = state is MapLoaded ? state.currentLocation : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MyLocationButton(
                  onPressed: () => context.read<MapCubit>().recenterToUserLocation(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  label: 'Report hazard incident button',
                  button: true,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showReportIncidentDialog(context, loc),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text(AppStrings.reportHazard),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
