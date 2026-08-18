import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/database/tracking_database.dart';
import 'data/repositories/tracking_repository_impl.dart';
import 'data/services/location_service.dart';
import 'data/sync/sync_engine.dart';
import 'presentation/cubits/admin/admin_cubit.dart';
import 'presentation/cubits/incident/incident_cubit.dart';
import 'presentation/cubits/map/map_cubit.dart';
import 'presentation/cubits/user_role_cubit.dart';
import 'presentation/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MapboxOptions.setAccessToken(AppConstants.defaultMapboxToken);

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );

  final database = TrackingDatabase();
  final syncEngine = SyncEngine(database: database);
  final repository = TrackingRepositoryImpl(
    database: database,
    syncEngine: syncEngine,
  );
  final locationService = LocationService();

  runApp(
    MyApp(
      repository: repository,
      locationService: locationService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final TrackingRepositoryImpl repository;
  final LocationService locationService;

  const MyApp({
    super.key,
    required this.repository,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserRoleCubit>(
          create: (_) => UserRoleCubit(),
        ),
        BlocProvider<MapCubit>(
          create: (_) => MapCubit(
            repository: repository,
            locationService: locationService,
          ),
        ),
        BlocProvider<IncidentCubit>(
          create: (_) => IncidentCubit(
            repository: repository,
          ),
        ),
        BlocProvider<AdminCubit>(
          create: (_) => AdminCubit(
            repository: repository,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
