import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../live_tv/domain/repositories/live_tv_repository.dart';
import '../../../series/domain/repositories/series_repository.dart';
import '../../../vod/domain/repositories/vod_repository.dart';
import '../entities/search_result.dart';

/// Fans out across live/VOD/series. Each repository's "get all" call
/// (category_id omitted) is cached in memory after the first search so
/// subsequent keystrokes filter locally instead of re-hitting the panel —
/// necessary given panels can have thousands of channels/categories.
class SearchAllUseCase {
  SearchAllUseCase(this._liveTvRepository, this._vodRepository, this._seriesRepository);

  final LiveTvRepository _liveTvRepository;
  final VodRepository _vodRepository;
  final SeriesRepository _seriesRepository;

  List<SearchResult>? _cache;

  static const _maxResults = 100;

  TaskEither<Failure, List<SearchResult>> call(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return TaskEither.right(const []);

    final cached = _cache;
    if (cached != null) {
      return TaskEither.right(_filter(cached, trimmed));
    }

    return _loadAll().map((all) {
      _cache = all;
      return _filter(all, trimmed);
    });
  }

  List<SearchResult> _filter(List<SearchResult> all, String query) {
    return all.where((r) => r.name.toLowerCase().contains(query)).take(_maxResults).toList();
  }

  TaskEither<Failure, List<SearchResult>> _loadAll() {
    return _liveTvRepository.getAllChannels().flatMap(
      (channels) => _vodRepository.getAllItems().flatMap(
        (vodItems) => _seriesRepository.getAllSeries().map(
          (series) => [
            ...channels.map((c) => SearchResult(
                  id: c.id,
                  name: c.name,
                  type: SearchResultType.live,
                  categoryId: c.categoryId,
                  streamIcon: c.streamIcon,
                )),
            ...vodItems.map((v) => SearchResult(
                  id: v.id,
                  name: v.name,
                  type: SearchResultType.vod,
                  categoryId: v.categoryId,
                  streamIcon: v.streamIcon,
                )),
            ...series.map((s) => SearchResult(
                  id: s.id,
                  name: s.name,
                  type: SearchResultType.series,
                  categoryId: s.categoryId,
                  streamIcon: s.cover,
                )),
          ],
        ),
      ),
    );
  }
}
