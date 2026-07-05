import 'package:xtream_code_client/xtream_code_client.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/xtream_client_factory.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/live_category.dart';
import '../../domain/entities/live_channel.dart';

/// Wraps the live-TV `player_api.php` actions. Caches one [XtreamClient] per
/// active profile (rebuilt if the logged-in profile changes) rather than
/// creating a new client per call.
class LiveTvRemoteDataSource {
  LiveTvRemoteDataSource(this._clientFactory, this._authCubit);

  final XtreamClientFactory _clientFactory;
  final AuthCubit _authCubit;

  XtreamClient? _cachedClient;
  String? _cachedProfileId;

  XtreamClient _client() {
    final state = _authCubit.state;
    if (state is! Authenticated) {
      throw const AuthFailure('No active profile to fetch live TV data.');
    }
    if (_cachedClient == null || _cachedProfileId != state.profile.id) {
      _cachedClient?.close();
      _cachedClient = _clientFactory.forProfile(state.profile);
      _cachedProfileId = state.profile.id;
    }
    return _cachedClient!;
  }

  Future<List<LiveCategory>> getCategories() async {
    try {
      final categories = await _client().liveStreamCategoriesData();
      return categories
          .where((c) => c.categoryId != null && c.categoryName != null)
          .map((c) => LiveCategory(id: c.categoryId!, name: c.categoryName!))
          .toList();
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }

  Future<List<LiveChannel>> getChannels(int categoryId) {
    return _fetchChannels(category: Category(categoryId: categoryId), fallbackCategoryId: categoryId);
  }

  /// Omitting `category_id` returns every channel across all categories in
  /// one call — used by search instead of iterating category-by-category.
  Future<List<LiveChannel>> getAllChannels() => _fetchChannels();

  Future<List<LiveChannel>> _fetchChannels({Category? category, int? fallbackCategoryId}) async {
    try {
      final items = await _client().liveStreamItemsData(category: category);
      return items
          .where((item) => item.streamId != null && item.name != null)
          .map((item) => LiveChannel(
                id: item.streamId!,
                name: item.name!,
                categoryId: item.categoryId ?? fallbackCategoryId ?? 0,
                streamIcon: item.streamIcon,
                epgChannelId: item.epgChannelId,
              ))
          .toList();
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }

  String getStreamUrl(int channelId, String format) {
    return _client().streamUrl(channelId, [format]);
  }
}
