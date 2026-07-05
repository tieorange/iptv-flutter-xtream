import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/series_category.dart';
import '../../domain/usecases/get_series_categories_usecase.dart';

sealed class SeriesCategoriesState {
  const SeriesCategoriesState();
}

final class SeriesCategoriesLoading extends SeriesCategoriesState {
  const SeriesCategoriesLoading();
}

final class SeriesCategoriesLoaded extends SeriesCategoriesState {
  const SeriesCategoriesLoaded(this.categories);

  final List<SeriesCategory> categories;
}

final class SeriesCategoriesError extends SeriesCategoriesState {
  const SeriesCategoriesError(this.message);

  final String message;
}

class SeriesCategoriesCubit extends Cubit<SeriesCategoriesState> {
  SeriesCategoriesCubit(this._getSeriesCategories) : super(const SeriesCategoriesLoading());

  final GetSeriesCategoriesUseCase _getSeriesCategories;

  Future<void> load() async {
    emit(const SeriesCategoriesLoading());
    final result = await _getSeriesCategories().run();
    result.fold(
      (failure) => emit(SeriesCategoriesError(failure.message)),
      (categories) => emit(SeriesCategoriesLoaded(categories)),
    );
  }
}
