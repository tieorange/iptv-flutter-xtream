import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/series_detail.dart';
import '../../domain/entities/series_episode.dart';

class SeriesEpisodesPage extends StatelessWidget {
  const SeriesEpisodesPage({super.key, required this.detail, required this.seasonNumber});

  final SeriesDetail detail;
  final int seasonNumber;

  @override
  Widget build(BuildContext context) {
    final episodes = detail.episodesBySeason[seasonNumber] ?? const <SeriesEpisode>[];

    return Scaffold(
      appBar: AppBar(title: Text('${detail.name} — Season $seasonNumber')),
      body: episodes.isEmpty
          ? const Center(child: Text('No episodes found.'))
          : ListView.builder(
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return ListTile(
                  leading: Text('${episode.episodeNum ?? index + 1}'),
                  title: Text(episode.title),
                  onTap: () => context.pushNamed(
                    'playerSeries',
                    pathParameters: {'episodeId': episode.id.toString()},
                    extra: episode,
                  ),
                );
              },
            ),
    );
  }
}
