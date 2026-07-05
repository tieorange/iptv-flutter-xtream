import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/favorite_item.dart';

abstract interface class FavoritesRepository {
  /// Favorites are scoped per [profileId] — switching profiles must show a
  /// different (or empty) list, never a shared one.
  TaskEither<Failure, List<FavoriteItem>> getFavorites(String profileId);

  TaskEither<Failure, bool> isFavorite(String profileId, FavoriteItem item);

  TaskEither<Failure, Unit> toggleFavorite(String profileId, FavoriteItem item);
}
