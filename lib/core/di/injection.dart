import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/xtream_client_factory.dart';
import '../router/auth_refresh_listenable.dart';
import '../storage/profile_local_store.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/add_profile_usecase.dart';
import '../../features/auth/domain/usecases/delete_profile_usecase.dart';
import '../../features/auth/domain/usecases/get_active_profile_usecase.dart';
import '../../features/auth/domain/usecases/get_saved_profiles_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/live_tv/data/datasources/live_tv_remote_datasource.dart';
import '../../features/live_tv/data/repositories/live_tv_repository_impl.dart';
import '../../features/live_tv/domain/repositories/live_tv_repository.dart';
import '../../features/live_tv/domain/usecases/get_live_categories_usecase.dart';
import '../../features/live_tv/domain/usecases/get_live_channels_usecase.dart';
import '../../features/player/data/engines/playback_engine_selector_impl.dart';
import '../../features/player/data/probes/hls_availability_probe.dart';
import '../../features/player/domain/repositories/playback_engine_selector.dart';
import '../../features/player/domain/usecases/play_channel_usecase.dart';

final getIt = GetIt.instance;

/// Registration order matters: core clients/storage first, then auth (whose
/// Cubit the router bridge depends on), then feature modules as they're
/// added in later milestones.
void configureDependencies() {
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
  getIt.registerLazySingleton<ProfileLocalStore>(
    () => ProfileLocalStore(getIt()),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => const AuthRemoteDataSource(),
  );
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt()),
  );

  getIt.registerFactory(() => LoginUseCase(getIt()));
  getIt.registerFactory(() => LogoutUseCase(getIt()));
  getIt.registerFactory(() => GetSavedProfilesUseCase(getIt()));
  getIt.registerFactory(() => AddProfileUseCase(getIt()));
  getIt.registerFactory(() => DeleteProfileUseCase(getIt()));
  getIt.registerFactory(() => GetActiveProfileUseCase(getIt()));

  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<AuthRefreshListenable>(
    () => AuthRefreshListenable(getIt<AuthCubit>().stream),
  );

  getIt.registerLazySingleton<XtreamClientFactory>(() => XtreamClientFactory());

  getIt.registerLazySingleton<LiveTvRemoteDataSource>(
    () => LiveTvRemoteDataSource(getIt(), getIt()),
  );
  getIt.registerLazySingleton<LiveTvRepository>(
    () => LiveTvRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => GetLiveCategoriesUseCase(getIt()));
  getIt.registerFactory(() => GetLiveChannelsUseCase(getIt()));

  // Player module last — it only depends on LiveTvRepository above.
  getIt.registerLazySingleton<HlsAvailabilityProbe>(() => HlsAvailabilityProbe(getIt()));
  getIt.registerLazySingleton<PlaybackEngineSelector>(
    () => PlaybackEngineSelectorImpl(getIt()),
  );
  getIt.registerFactory(() => PlayChannelUseCase(getIt(), getIt()));
}
