import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/series_show.dart';
import '../../domain/usecases/get_series_usecase.dart';

sealed class SeriesListState {
  const SeriesListState();
}

final class SeriesListLoading extends SeriesListState {
  const SeriesListLoading();
}

final class SeriesListLoaded extends SeriesListState {
  const SeriesListLoaded(this.series);

  final List<SeriesShow> series;
}

final class SeriesListError extends SeriesListState {
  const SeriesListError(this.message);

  final String message;
}

class SeriesListCubit extends Cubit<SeriesListState> {
  SeriesListCubit(this._getSeries) : super(const SeriesListLoading());

  final GetSeriesUseCase _getSeries;

  Future<void> load(int categoryId) async {
    emit(const SeriesListLoading());
    final result = await _getSeries(categoryId).run();
    result.fold(
      (failure) => emit(SeriesListError(failure.message)),
      (series) => emit(SeriesListLoaded(series)),
    );
  }
}
