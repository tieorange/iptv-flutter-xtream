import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/favorite_item.dart';
import '../../domain/usecases/get_favorites_usecase.dart';

sealed class FavoritesState {
  const FavoritesState();
}

final class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

final class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.items);

  final List<FavoriteItem> items;
}

final class FavoritesError extends FavoritesState {
  const FavoritesError(this.message);

  final String message;
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._getFavorites) : super(const FavoritesLoading());

  final GetFavoritesUseCase _getFavorites;

  Future<void> load(String profileId) async {
    emit(const FavoritesLoading());
    final result = await _getFavorites(profileId).run();
    result.fold(
      (failure) => emit(FavoritesError(failure.message)),
      (items) => emit(FavoritesLoaded(items)),
    );
  }
}
