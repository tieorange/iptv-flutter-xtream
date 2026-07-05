import 'series_episode.dart';
import 'series_season.dart';

class SeriesDetail {
  const SeriesDetail({
    required this.name,
    required this.seasons,
    required this.episodesBySeason,
    this.plot,
    this.coverUrl,
  });

  final String name;
  final String? plot;
  final String? coverUrl;
  final List<SeriesSeason> seasons;
  final Map<int, List<SeriesEpisode>> episodesBySeason;
}
