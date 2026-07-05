import 'package:xtream_code_client/xtream_code_client.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/xtream_client_factory.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/vod_category.dart';
import '../../domain/entities/vod_detail.dart';
import '../../domain/entities/vod_item.dart' as domain;

class VodRemoteDataSource {
  VodRemoteDataSource(this._clientFactory, this._authCubit);

  final XtreamClientFactory _clientFactory;
  final AuthCubit _authCubit;

  XtreamClient? _cachedClient;
  String? _cachedProfileId;

  XtreamClient _client() {
    final state = _authCubit.state;
    if (state is! Authenticated) {
      throw const AuthFailure('No active profile to fetch VOD data.');
    }
    if (_cachedClient == null || _cachedProfileId != state.profile.id) {
      _cachedClient?.close();
      _cachedClient = _clientFactory.forProfile(state.profile);
      _cachedProfileId = state.profile.id;
    }
    return _cachedClient!;
  }

  Future<List<VodCategory>> getCategories() async {
    try {
      final categories = await _client().vodCategoriesData();
      return categories
          .where((c) => c.categoryId != null && c.categoryName != null)
          .map((c) => VodCategory(id: c.categoryId!, name: c.categoryName!))
          .toList();
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }

  Future<List<domain.VodItem>> getItems(int categoryId) async {
    try {
      final items = await _client().vodItemsData(
        category: Category(categoryId: categoryId),
      );
      return items
          .where((item) => item.streamId != null && item.name != null)
          .map((item) => domain.VodItem(
                id: item.streamId!,
                name: item.name!,
                categoryId: item.categoryId ?? categoryId,
                streamIcon: item.streamIcon,
                containerExtension: item.containerExtension,
              ))
          .toList();
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }

  Future<VodDetail> getDetail(domain.VodItem item) async {
    try {
      final info = await _client().vodInfoData(VodItem(
        streamId: item.id,
        containerExtension: item.containerExtension,
      ));
      return VodDetail(
        streamId: info.movieData.streamId ?? item.id,
        name: info.info.name ?? item.name,
        description: info.info.description ?? info.info.plot,
        coverUrl: info.info.coverBig ?? info.info.movieImage ?? item.streamIcon,
        genre: info.info.genre,
        durationSecs: info.info.durationSecs,
        containerExtension: info.movieData.containerExtension ?? item.containerExtension,
      );
    } on RequestException catch (e) {
      throw NetworkFailure(e.message);
    } on ParseException catch (e) {
      throw ParseFailure(e.toString());
    }
  }

  String getStreamUrl(int streamId, String containerExtension) {
    return _client().movieUrl(streamId, containerExtension);
  }
}
