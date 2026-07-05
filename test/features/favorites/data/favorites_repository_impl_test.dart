import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/favorites/data/datasources/favorites_local_datasource.dart';
import 'package:iptv/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:iptv/features/favorites/domain/entities/favorite_item.dart';

class _MockLocal extends Mock implements FavoritesLocalDataSource {}

void main() {
  late _MockLocal local;
  late FavoritesRepositoryImpl repository;

  const item = FavoriteItem(itemId: 1, itemType: FavoriteItemType.live, name: 'BBC');

  setUp(() {
    local = _MockLocal();
    repository = FavoritesRepositoryImpl(local);
  });

  test('getFavorites returns Right(items) scoped to the profile id', () async {
    final favorites = [item];
    when(() => local.getFavorites('p1')).thenAnswer((_) async => favorites);

    final result = await repository.getFavorites('p1').run();

    expect(result, Either<Failure, List<FavoriteItem>>.right(favorites));
    verify(() => local.getFavorites('p1')).called(1);
  });

  test('isFavorite reflects the stored list', () async {
    when(() => local.getFavorites('p1')).thenAnswer((_) async => [item]);

    final result = await repository.isFavorite('p1', item).run();

    expect(result, Either<Failure, bool>.right(true));
  });

  test('toggleFavorite delegates to the local datasource', () async {
    when(() => local.toggleFavorite('p1', item)).thenAnswer((_) async {});

    final result = await repository.toggleFavorite('p1', item).run();

    expect(result, Either<Failure, Unit>.right(unit));
    verify(() => local.toggleFavorite('p1', item)).called(1);
  });
}
