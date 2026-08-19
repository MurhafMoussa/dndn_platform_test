import 'package:get_it/get_it.dart';

import '../../data/database/tracking_database.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../data/services/home_widget_service.dart';
import '../../data/services/location_service.dart';
import '../../data/sync/sync_engine.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../../presentation/cubits/admin/admin_cubit.dart';
import '../../presentation/cubits/incident/incident_cubit.dart';
import '../../presentation/cubits/location_permission/location_permission_cubit.dart';
import '../../presentation/cubits/map/map_cubit.dart';
import '../../presentation/cubits/user_role_cubit.dart';

final GetIt getIt = GetIt.instance;

/// Sets up dependency injection service locator for all repositories, data sources, services, and cubits.
Future<void> setupServiceLocator({
  TrackingDatabase? databaseOverride,
  TrackingRepository? repositoryOverride,
  LocationService? locationServiceOverride,
  HomeWidgetService? homeWidgetServiceOverride,
}) async {
  // Clear all existing registrations if re-initializing (e.g., in tests)
  await getIt.reset();

  // Database
  final database = databaseOverride ?? TrackingDatabase();
  getIt.registerLazySingleton<TrackingDatabase>(() => database);

  // Sync Engine
  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(database: getIt<TrackingDatabase>()),
  );

  // Repository
  final repository = repositoryOverride ??
      TrackingRepositoryImpl(
        database: getIt<TrackingDatabase>(),
        syncEngine: getIt<SyncEngine>(),
      );
  getIt.registerLazySingleton<TrackingRepository>(() => repository);

  // Services
  final locationService = locationServiceOverride ?? LocationService();
  getIt.registerLazySingleton<LocationService>(() => locationService);

  final homeWidgetService = homeWidgetServiceOverride ?? HomeWidgetService();
  getIt.registerLazySingleton<HomeWidgetService>(() => homeWidgetService);

  // Cubits
  getIt.registerFactory<UserRoleCubit>(() => UserRoleCubit());

  getIt.registerFactory<LocationPermissionCubit>(
    () => LocationPermissionCubit(
      locationService: getIt<LocationService>(),
    ),
  );

  getIt.registerFactory<MapCubit>(
    () => MapCubit(
      repository: getIt<TrackingRepository>(),
      locationService: getIt<LocationService>(),
      homeWidgetService: getIt<HomeWidgetService>(),
    ),
  );

  getIt.registerFactory<IncidentCubit>(
    () => IncidentCubit(
      repository: getIt<TrackingRepository>(),
    ),
  );

  getIt.registerFactory<AdminCubit>(
    () => AdminCubit(
      repository: getIt<TrackingRepository>(),
    ),
  );
}
