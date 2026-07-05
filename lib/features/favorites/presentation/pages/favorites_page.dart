import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../../../vod/domain/entities/vod_item.dart';
import '../../../vod/presentation/pages/vod_detail_page.dart';
import '../../../series/domain/entities/series_show.dart';
import '../../../series/presentation/pages/series_seasons_page.dart';
import '../../domain/entities/favorite_item.dart';
import '../../domain/usecases/get_favorites_usecase.dart';
import '../cubit/favorites_cubit.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late final FavoritesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = FavoritesCubit(getIt<GetFavoritesUseCase>());
    _reload();
  }

  String? get _profileId {
    final state = getIt<AuthCubit>().state;
    return state is Authenticated ? state.profile.id : null;
  }

  void _reload() {
    final profileId = _profileId;
    if (profileId != null) _cubit.load(profileId);
  }

  void _open(FavoriteItem item) {
    final page = switch (item.itemType) {
      FavoriteItemType.live => PlayerPage(
          channel: LiveChannel(id: item.itemId, name: item.name, categoryId: 0, streamIcon: item.streamIcon),
        ),
      FavoriteItemType.vod => VodDetailPage(
          item: VodItem(id: item.itemId, name: item.name, categoryId: 0, streamIcon: item.streamIcon),
        ),
      FavoriteItemType.series => SeriesSeasonsPage(
          show: SeriesShow(id: item.itemId, name: item.name, categoryId: 0, cover: item.streamIcon),
        ),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, state) {
            return switch (state) {
              FavoritesLoading() => const Center(child: CircularProgressIndicator()),
              FavoritesError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _reload, child: const Text('Retry')),
                    ],
                  ),
                ),
              FavoritesLoaded(items: final items) => items.isEmpty
                  ? const Center(child: Text('No favorites yet.'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          leading: Icon(switch (item.itemType) {
                            FavoriteItemType.live => Icons.live_tv,
                            FavoriteItemType.vod => Icons.movie,
                            FavoriteItemType.series => Icons.tv,
                          }),
                          title: Text(item.name),
                          onTap: () => _open(item),
                        );
                      },
                    ),
            };
          },
        ),
      ),
    );
  }
}
