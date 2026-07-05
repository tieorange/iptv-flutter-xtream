import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/favorite_item.dart';
import '../repositories/favorites_repository.dart';

class ToggleFavoriteUseCase {
  const ToggleFavoriteUseCase(this._repository);

  final FavoritesRepository _repository;

  TaskEither<Failure, Unit> call(String profileId, FavoriteItem item) =>
      _repository.toggleFavorite(profileId, item);
}
