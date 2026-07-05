import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/favorite_item.dart';
import '../repositories/favorites_repository.dart';

class GetFavoritesUseCase {
  const GetFavoritesUseCase(this._repository);

  final FavoritesRepository _repository;

  TaskEither<Failure, List<FavoriteItem>> call(String profileId) =>
      _repository.getFavorites(profileId);
}
