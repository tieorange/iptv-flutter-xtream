import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import '../theme/placeholder_page.dart';
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
              builder: (context, state) => const PlaceholderPage('VOD categories'),
              routes: [
                GoRoute(
                  path: ':categoryId',
                  name: 'vodItems',
                  builder: (context, state) => const PlaceholderPage('VOD items'),
                  routes: [
                    GoRoute(
                      path: ':itemId',
                      name: 'vodDetail',
                      builder: (context, state) => const PlaceholderPage('VOD detail'),
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
              builder: (context, state) => const PlaceholderPage('Series categories'),
              routes: [
                GoRoute(
                  path: ':categoryId',
                  name: 'seriesList',
                  builder: (context, state) => const PlaceholderPage('Series list'),
                  routes: [
                    GoRoute(
                      path: ':seriesId',
                      name: 'seriesSeasons',
                      builder: (context, state) => const PlaceholderPage('Series seasons'),
                      routes: [
                        GoRoute(
                          path: ':seasonId',
                          name: 'seriesEpisodes',
                          builder: (context, state) => const PlaceholderPage('Series episodes'),
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
              builder: (context, state) => const PlaceholderPage('Search'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/favorites',
              name: 'favorites',
              builder: (context, state) => const PlaceholderPage('Favorites'),
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
        builder: (context, state) => const PlaceholderPage('Player: VOD'),
      ),
      GoRoute(
        path: '/player/series/:episodeId',
        name: 'playerSeries',
        builder: (context, state) => const PlaceholderPage('Player: series'),
      ),
    ],
  );
}
