import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../favorites/domain/entities/favorite_item.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/entities/series_show.dart';
import '../../domain/usecases/get_series_detail_usecase.dart';
import '../cubit/series_detail_cubit.dart';

/// Loads the full series payload once (seasons + episodes-by-season) and
/// shows the season list. The episodes page receives the already-loaded
/// [SeriesDetail] via `extra` rather than re-fetching per season tap.
class SeriesSeasonsPage extends StatelessWidget {
  const SeriesSeasonsPage({super.key, required this.show});

  final SeriesShow show;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SeriesDetailCubit(getIt<GetSeriesDetailUseCase>())..load(show),
      child: Scaffold(
        appBar: AppBar(
          title: Text(show.name),
          actions: [
            FavoriteButton(
              item: FavoriteItem(
                itemId: show.id,
                itemType: FavoriteItemType.series,
                name: show.name,
                streamIcon: show.cover,
              ),
            ),
          ],
        ),
        body: BlocBuilder<SeriesDetailCubit, SeriesDetailState>(
          builder: (context, state) {
            return switch (state) {
              SeriesDetailLoading() => const Center(child: CircularProgressIndicator()),
              SeriesDetailError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<SeriesDetailCubit>().load(show),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              SeriesDetailLoaded(detail: final detail) => detail.seasons.isEmpty
                  ? const Center(child: Text('No seasons found.'))
                  : ListView.builder(
                      itemCount: detail.seasons.length,
                      itemBuilder: (context, index) {
                        final season = detail.seasons[index];
                        return ListTile(
                          title: Text(season.name ?? 'Season ${season.seasonNumber}'),
                          subtitle: season.episodeCount != null
                              ? Text('${season.episodeCount} episodes')
                              : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.pushNamed(
                            'seriesEpisodes',
                            pathParameters: {
                              'categoryId': show.categoryId.toString(),
                              'seriesId': show.id.toString(),
                              'seasonId': season.seasonNumber.toString(),
                            },
                            extra: detail,
                          ),
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
