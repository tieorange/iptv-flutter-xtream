import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/favorite_item.dart';
import '../repositories/favorites_repository.dart';

class IsFavoriteUseCase {
  const IsFavoriteUseCase(this._repository);

  final FavoritesRepository _repository;

  TaskEither<Failure, bool> call(String profileId, FavoriteItem item) =>
      _repository.isFavorite(profileId, item);
}
