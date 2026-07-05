import 'package:xtream_code_client/xtream_code_client.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/xtream_client_factory.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/series_category.dart';
import '../../domain/entities/series_detail.dart';
import '../../domain/entities/series_episode.dart';
import '../../domain/entities/series_season.dart';
import '../../domain/entities/series_show.dart' as domain;

class SeriesRemoteDataSource {
  SeriesRemoteDataSource(this._clientFactory, this._authCubit);

  final XtreamClientFactory _clientFactory;
  final AuthCubit _authCubit;

  XtreamClient? _cachedClient;
  String? _cachedProfileId;

  XtreamClient _client() {
    final state = _authCubit.state;
    if (state is! Authenticated) {
      throw const AuthFailure('No active profile to fetch series data.');
    }
    if (_cachedClient == null || _cachedProfileId != state.profile.id) {
      _cachedClient?.close();
      _cachedClient = _clientFactory.forProfile(state.profile);
      _cachedProfileId = state.profile.id;
    }
    return _cachedClient!;
  }

  Future<List<SeriesCategory>> getCategories() async {
    try {
      final categories = await _client().seriesCategoriesData();
      return categories
          .where((c) => c.categoryId != null && c.categoryName != null)
          .map((c) => SeriesCategory(id: c.categoryId!, name: c.categoryName!))
          .toList();
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }

  Future<List<domain.SeriesShow>> getSeries(int categoryId) {
    return _fetchSeries(category: Category(categoryId: categoryId), fallbackCategoryId: categoryId);
  }

  /// All series across every category — used by search instead of
  /// iterating category-by-category.
  Future<List<domain.SeriesShow>> getAllSeries() => _fetchSeries();

  Future<List<domain.SeriesShow>> _fetchSeries({Category? category, int? fallbackCategoryId}) async {
    try {
      final items = await _client().seriesItemsData(category: category);
      return items
          .where((item) => item.seriesId != null && item.name != null)
          .map((item) => domain.SeriesShow(
                id: item.seriesId!,
                name: item.name!,
                categoryId: item.categoryId ?? fallbackCategoryId ?? 0,
                cover: item.cover,
                plot: item.plot,
              ))
          .toList();
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }

  Future<SeriesDetail> getSeriesDetail(domain.SeriesShow show) async {
    try {
      final info = await _client().seriesInfoData(SeriesItem(seriesId: show.id));

      final seasons = (info.seasons ?? const [])
          .where((s) => s.seasonNumber != null)
          .map((s) => SeriesSeason(
                seasonNumber: s.seasonNumber!,
                name: s.name,
                episodeCount: s.episodeCount,
              ))
          .toList();

      final episodesBySeason = <int, List<SeriesEpisode>>{};
      for (final entry in (info.episodes ?? const {}).entries) {
        final seasonNumber = int.tryParse(entry.key);
        if (seasonNumber == null) continue;
        episodesBySeason[seasonNumber] = entry.value
            .where((e) => e.id != null)
            .map((e) => SeriesEpisode(
                  id: e.id!,
                  title: e.title ?? 'Episode ${e.episodeNum ?? ''}',
                  seasonNumber: e.season ?? seasonNumber,
                  episodeNum: e.episodeNum,
                  containerExtension: e.containerExtension,
                  plot: e.info.plot,
                ))
            .toList();
      }

      return SeriesDetail(
        name: info.info.name ?? show.name,
        plot: info.info.plot ?? show.plot,
        coverUrl: info.info.cover ?? show.cover,
        seasons: seasons,
        episodesBySeason: episodesBySeason,
      );
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }

  String getEpisodeStreamUrl(int episodeId, String containerExtension) {
    return _client().seriesUrl(episodeId, containerExtension);
  }
}
