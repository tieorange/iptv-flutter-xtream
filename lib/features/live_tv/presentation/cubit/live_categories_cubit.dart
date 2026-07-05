import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/live_category.dart';
import '../../domain/usecases/get_live_categories_usecase.dart';

sealed class LiveCategoriesState {
  const LiveCategoriesState();
}

final class LiveCategoriesLoading extends LiveCategoriesState {
  const LiveCategoriesLoading();
}

final class LiveCategoriesLoaded extends LiveCategoriesState {
  const LiveCategoriesLoaded(this.categories);

  final List<LiveCategory> categories;

  @override
  bool operator ==(Object other) =>
      other is LiveCategoriesLoaded &&
      other.categories.length == categories.length &&
      other.categories.every((c) => categories.any((mine) => mine.id == c.id));

  @override
  int get hashCode => Object.hashAll(categories.map((c) => c.id));
}

final class LiveCategoriesError extends LiveCategoriesState {
  const LiveCategoriesError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is LiveCategoriesError && other.message == message;

  @override
  int get hashCode => message.hashCode;
}

class LiveCategoriesCubit extends Cubit<LiveCategoriesState> {
  LiveCategoriesCubit(this._getLiveCategories) : super(const LiveCategoriesLoading());

  final GetLiveCategoriesUseCase _getLiveCategories;

  Future<void> load() async {
    emit(const LiveCategoriesLoading());
    final result = await _getLiveCategories().run();
    result.fold(
      (failure) => emit(LiveCategoriesError(failure.message)),
      (categories) => emit(LiveCategoriesLoaded(categories)),
    );
  }
}
