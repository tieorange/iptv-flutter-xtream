import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import 'auth_refresh_listenable.dart';
import 'home_shell.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/add_edit_profile_page.dart';
import '../../features/auth/presentation/pages/profile_list_page.dart';
import '../../features/live_tv/domain/entities/live_category.dart';
import '../../features/live_tv/presentation/pages/live_categories_page.dart';
import '../../features/live_tv/presentation/pages/live_channels_page.dart';
import '../../features/live_tv/domain/entities/live_channel.dart';
import '../../features/player/presentation/pages/player_page.dart';
import '../../features/vod/domain/entities/vod_category.dart';
import '../../features/vod/domain/entities/vod_detail.dart';
import '../../features/vod/domain/entities/vod_item.dart';
import '../../features/vod/presentation/pages/vod_categories_page.dart';
import '../../features/vod/presentation/pages/vod_detail_page.dart';
import '../../features/vod/presentation/pages/vod_items_page.dart';
import '../../features/vod/presentation/pages/vod_player_page.dart';
import '../../features/series/domain/entities/series_category.dart';
import '../../features/series/domain/entities/series_detail.dart';
import '../../features/series/domain/entities/series_episode.dart';
import '../../features/series/domain/entities/series_show.dart';
import '../../features/series/presentation/pages/series_categories_page.dart';
import '../../features/series/presentation/pages/series_episodes_page.dart';
import '../../features/series/presentation/pages/series_list_page.dart';
import '../../features/series/presentation/pages/series_player_page.dart';
import '../../features/series/presentation/pages/series_seasons_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/search/presentation/pages/search_page.dart';

/// Full Phase-1 route table from PLAN.md, wired up front in M0 so every
/// later milestone only swaps a placeholder page for the real one — the
/// route table itself and the auth guard don't change shape after this.
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/profiles',
    refreshListenable: getIt<AuthRefreshListenable>(),
    redirect: (context, state) {
      final authState = getIt<AuthCubit>().state;
      final location = state.matchedLocation;

      if (authState is AuthInitial || authState is AuthLoading) return null;
      if (authState is Unauthenticated && !location.startsWith('/profiles')) {
        return '/profiles';
      }
      if (authState is Authenticated && location.startsWith('/profiles')) {
        return '/home/live';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/profiles',
        name: 'profiles',
        builder: (context, state) => const ProfileListPage(),
      ),
      GoRoute(
        path: '/profiles/add',
        name: 'profilesAdd',
        builder: (context, state) => const AddEditProfilePage(),
      ),
      GoRoute(
        path: '/profiles/:profileId/edit',
        name: 'profilesEdit',
        builder: (context, state) =>
            AddEditProfilePage(profileId: state.pathParameters['profileId']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/live',
              name: 'liveCategories',
              builder: (context, state) => const LiveCategoriesPage(),
              routes: [
                GoRoute(
                  path: ':categoryId',
                  name: 'liveChannels',
                  builder: (context, state) => LiveChannelsPage(
                    categoryId: int.parse(state.pathParameters['categoryId']!),
                    category: state.extra as LiveCategory?,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/vod',
              name: 'vodCategories',
              builder: (context, state) => const VodCategoriesPage(),
              routes: [
                GoRoute(
                  path: ':categoryId',
                  name: 'vodItems',
                  builder: (context, state) => VodItemsPage(
                    categoryId: int.parse(state.pathParameters['categoryId']!),
                    category: state.extra as VodCategory?,
                  ),
                  routes: [
                    GoRoute(
                      path: ':itemId',
                      name: 'vodDetail',
                      builder: (context, state) => VodDetailPage(item: state.extra as VodItem),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/series',
              name: 'seriesCategories',
              builder: (context, state) => const SeriesCategoriesPage(),
              routes: [
                GoRoute(
                  path: ':categoryId',
                  name: 'seriesList',
                  builder: (context, state) => SeriesListPage(
                    categoryId: int.parse(state.pathParameters['categoryId']!),
                    category: state.extra as SeriesCategory?,
                  ),
                  routes: [
                    GoRoute(
                      path: ':seriesId',
                      name: 'seriesSeasons',
                      builder: (context, state) => SeriesSeasonsPage(show: state.extra as SeriesShow),
                      routes: [
                        GoRoute(
                          path: ':seasonId',
                          name: 'seriesEpisodes',
                          builder: (context, state) => SeriesEpisodesPage(
                            detail: state.extra as SeriesDetail,
                            seasonNumber: int.parse(state.pathParameters['seasonId']!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/search',
              name: 'search',
              builder: (context, state) => const SearchPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/favorites',
              name: 'favorites',
              builder: (context, state) => const FavoritesPage(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/player/live/:channelId',
        name: 'playerLive',
        builder: (context, state) => PlayerPage(channel: state.extra as LiveChannel),
      ),
      GoRoute(
        path: '/player/vod/:itemId',
        name: 'playerVod',
        builder: (context, state) => VodPlayerPage(detail: state.extra as VodDetail),
      ),
      GoRoute(
        path: '/player/series/:episodeId',
        name: 'playerSeries',
        builder: (context, state) => SeriesPlayerPage(episode: state.extra as SeriesEpisode),
      ),
    ],
  );
}
