enum SearchResultType { live, vod, series }

class SearchResult {
  const SearchResult({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryId,
    this.streamIcon,
  });

  final int id;
  final String name;
  final SearchResultType type;
  final int categoryId;
  final String? streamIcon;
}
