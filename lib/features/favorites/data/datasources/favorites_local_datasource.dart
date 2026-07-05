import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/favorite_item.dart';

/// Favorites aren't sensitive (unlike credentials), so this uses
/// SharedPreferences rather than the Keychain-backed [SecureStorage] —
/// keyed per profile id so switching profiles shows a different list.
class FavoritesLocalDataSource {
  Future<List<FavoriteItem>> getFavorites(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(profileId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> toggleFavorite(String profileId, FavoriteItem item) async {
    final favorites = await getFavorites(profileId);
    final exists = favorites.contains(item);
    final updated = exists
        ? favorites.where((f) => f != item).toList()
        : [...favorites, item];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(profileId), jsonEncode(updated.map(_toJson).toList()));
  }

  String _key(String profileId) => 'favorites:$profileId';

  Map<String, dynamic> _toJson(FavoriteItem item) => {
        'itemId': item.itemId,
        'itemType': item.itemType.name,
        'name': item.name,
        'streamIcon': item.streamIcon,
      };

  FavoriteItem _fromJson(Map<String, dynamic> json) => FavoriteItem(
        itemId: json['itemId'] as int,
        itemType: FavoriteItemType.values.byName(json['itemType'] as String),
        name: json['name'] as String,
        streamIcon: json['streamIcon'] as String?,
      );
}
