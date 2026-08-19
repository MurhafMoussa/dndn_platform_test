import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'presentation/cubits/admin/admin_cubit.dart';
import 'presentation/cubits/incident/incident_cubit.dart';
import 'presentation/cubits/location_permission/location_permission_cubit.dart';
import 'presentation/cubits/map/map_cubit.dart';
import 'presentation/cubits/user_role_cubit.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/widgets/location_permission_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MapboxOptions.setAccessToken(AppConstants.defaultMapboxToken);

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );

  await setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserRoleCubit>(
          create: (_) => getIt<UserRoleCubit>(),
        ),
        BlocProvider<LocationPermissionCubit>(
          create: (_) => getIt<LocationPermissionCubit>()..checkPermission(),
        ),
        BlocProvider<MapCubit>(
          create: (_) => getIt<MapCubit>(),
        ),
        BlocProvider<IncidentCubit>(
          create: (_) => getIt<IncidentCubit>(),
        ),
        BlocProvider<AdminCubit>(
          create: (_) => getIt<AdminCubit>(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return LocationPermissionGuard(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
