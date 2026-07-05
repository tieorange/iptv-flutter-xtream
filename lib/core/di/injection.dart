import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
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
import '../../features/epg/data/datasources/epg_remote_datasource.dart';
import '../../features/epg/data/repositories/epg_repository_impl.dart';
import '../../features/epg/domain/repositories/epg_repository.dart';
import '../../features/epg/domain/usecases/get_now_next_usecase.dart';
import '../../features/favorites/data/datasources/favorites_local_datasource.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/get_favorites_usecase.dart';
import '../../features/favorites/domain/usecases/is_favorite_usecase.dart';
import '../../features/favorites/domain/usecases/toggle_favorite_usecase.dart';
import '../../features/live_tv/data/datasources/live_tv_remote_datasource.dart';
import '../../features/live_tv/data/repositories/live_tv_repository_impl.dart';
import '../../features/live_tv/domain/repositories/live_tv_repository.dart';
import '../../features/live_tv/domain/usecases/get_live_categories_usecase.dart';
import '../../features/live_tv/domain/usecases/get_live_channels_usecase.dart';
import '../../features/player/data/engines/playback_engine_selector_impl.dart';
import '../../features/player/data/probes/hls_availability_probe.dart';
import '../../features/player/domain/repositories/playback_engine_selector.dart';
import '../../features/player/domain/usecases/play_channel_usecase.dart';
import '../../features/player/domain/usecases/play_series_episode_usecase.dart';
import '../../features/player/domain/usecases/play_vod_item_usecase.dart';
import '../../features/player/presentation/cubit/player_cubit.dart';
import '../../features/search/domain/usecases/search_all_usecase.dart';
import '../../features/series/data/datasources/series_remote_datasource.dart';
import '../../features/series/data/repositories/series_repository_impl.dart';
import '../../features/series/domain/repositories/series_repository.dart';
import '../../features/series/domain/usecases/get_series_categories_usecase.dart';
import '../../features/series/domain/usecases/get_series_detail_usecase.dart';
import '../../features/series/domain/usecases/get_series_usecase.dart';
import '../../features/vod/data/datasources/vod_remote_datasource.dart';
import '../../features/vod/data/repositories/vod_repository_impl.dart';
import '../../features/vod/domain/repositories/vod_repository.dart';
import '../../features/vod/domain/usecases/get_vod_categories_usecase.dart';
import '../../features/vod/domain/usecases/get_vod_detail_usecase.dart';
import '../../features/vod/domain/usecases/get_vod_items_usecase.dart';

final getIt = GetIt.instance;

/// Registration order matters: core clients/storage first, then auth (whose
/// Cubit the router bridge depends on), then feature modules as they're
/// added in later milestones.
void configureDependencies() {
  getIt.registerLazySingleton<Dio>(() => buildApiClient());
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

  getIt.registerLazySingleton<EpgRemoteDataSource>(
    () => EpgRemoteDataSource(getIt(), getIt()),
  );
  getIt.registerLazySingleton<EpgRepository>(() => EpgRepositoryImpl(getIt()));
  getIt.registerFactory(() => GetNowNextUseCase(getIt()));

  getIt.registerLazySingleton<FavoritesLocalDataSource>(() => FavoritesLocalDataSource());
  getIt.registerLazySingleton<FavoritesRepository>(() => FavoritesRepositoryImpl(getIt()));
  getIt.registerFactory(() => GetFavoritesUseCase(getIt()));
  getIt.registerFactory(() => IsFavoriteUseCase(getIt()));
  getIt.registerFactory(() => ToggleFavoriteUseCase(getIt()));

  // Player module last — it only depends on LiveTvRepository above.
  getIt.registerLazySingleton<HlsAvailabilityProbe>(() => HlsAvailabilityProbe(getIt()));
  getIt.registerLazySingleton<PlaybackEngineSelector>(
    () => PlaybackEngineSelectorImpl(getIt()),
  );
  getIt.registerFactory(() => PlayChannelUseCase(getIt(), getIt()));

  getIt.registerLazySingleton<VodRemoteDataSource>(
    () => VodRemoteDataSource(getIt(), getIt()),
  );
  getIt.registerLazySingleton<VodRepository>(() => VodRepositoryImpl(getIt()));
  getIt.registerFactory(() => GetVodCategoriesUseCase(getIt()));
  getIt.registerFactory(() => GetVodItemsUseCase(getIt()));
  getIt.registerFactory(() => GetVodDetailUseCase(getIt()));
  getIt.registerFactory(() => PlayVodItemUseCase(getIt()));

  getIt.registerLazySingleton<SeriesRemoteDataSource>(
    () => SeriesRemoteDataSource(getIt(), getIt()),
  );
  getIt.registerLazySingleton<SeriesRepository>(() => SeriesRepositoryImpl(getIt()));
  getIt.registerFactory(() => GetSeriesCategoriesUseCase(getIt()));
  getIt.registerFactory(() => GetSeriesUseCase(getIt()));
  getIt.registerFactory(() => GetSeriesDetailUseCase(getIt()));
  getIt.registerFactory(() => PlaySeriesEpisodeUseCase(getIt()));

  // PlayerCubit depends on all three "play" use cases above, so it's
  // registered last; it's a factory (page-scoped), never a singleton.
  getIt.registerFactory(() => PlayerCubit(getIt(), getIt(), getIt()));

  // Singleton: caches the flat live/VOD/series lists in memory for the
  // session so repeated searches don't re-fetch thousands of items.
  getIt.registerLazySingleton(() => SearchAllUseCase(getIt(), getIt(), getIt()));
}
