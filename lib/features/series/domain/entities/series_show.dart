class SeriesShow {
  const SeriesShow({
    required this.id,
    required this.name,
    required this.categoryId,
    this.cover,
    this.plot,
  });

  final int id;
  final String name;
  final int categoryId;
  final String? cover;
  final String? plot;
}
