import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iptv/features/favorites/data/datasources/favorites_local_datasource.dart';
import 'package:iptv/features/favorites/domain/entities/favorite_item.dart';

void main() {
  late FavoritesLocalDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = FavoritesLocalDataSource();
  });

  const bbc = FavoriteItem(itemId: 1, itemType: FavoriteItemType.live, name: 'BBC');
  const espn = FavoriteItem(itemId: 2, itemType: FavoriteItemType.vod, name: 'ESPN');

  test('toggle adds then removes an item', () async {
    expect(await dataSource.getFavorites('p1'), isEmpty);

    await dataSource.toggleFavorite('p1', bbc);
    expect(await dataSource.getFavorites('p1'), [bbc]);

    await dataSource.toggleFavorite('p1', bbc);
    expect(await dataSource.getFavorites('p1'), isEmpty);
  });

  test('favorites are scoped per profile id', () async {
    await dataSource.toggleFavorite('p1', bbc);
    await dataSource.toggleFavorite('p2', espn);

    expect(await dataSource.getFavorites('p1'), [bbc]);
    expect(await dataSource.getFavorites('p2'), [espn]);
  });
}
