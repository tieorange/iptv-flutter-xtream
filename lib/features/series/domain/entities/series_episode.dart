class SeriesEpisode {
  const SeriesEpisode({
    required this.id,
    required this.title,
    required this.seasonNumber,
    this.episodeNum,
    this.containerExtension,
    this.plot,
  });

  final int id;
  final String title;
  final int seasonNumber;
  final int? episodeNum;
  final String? containerExtension;
  final String? plot;
}
