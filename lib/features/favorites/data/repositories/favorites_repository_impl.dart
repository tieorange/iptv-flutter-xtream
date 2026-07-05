import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/url_scrubber.dart';
import '../../domain/entities/favorite_item.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._local);

  final FavoritesLocalDataSource _local;

  @override
  TaskEither<Failure, List<FavoriteItem>> getFavorites(String profileId) {
    return TaskEither.tryCatch(() => _local.getFavorites(profileId), _toFailure);
  }

  @override
  TaskEither<Failure, bool> isFavorite(String profileId, FavoriteItem item) {
    return TaskEither.tryCatch(
      () async => (await _local.getFavorites(profileId)).contains(item),
      _toFailure,
    );
  }

  @override
  TaskEither<Failure, Unit> toggleFavorite(String profileId, FavoriteItem item) {
    return TaskEither.tryCatch(
      () async {
        await _local.toggleFavorite(profileId, item);
        return unit;
      },
      _toFailure,
    );
  }

  Failure _toFailure(Object error, StackTrace _) {
    if (error is Failure) return error;
    return UnknownFailure(scrubMessage(error.toString()));
  }
}
