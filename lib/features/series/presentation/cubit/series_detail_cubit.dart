import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/series_detail.dart';
import '../../domain/entities/series_show.dart';
import '../../domain/usecases/get_series_detail_usecase.dart';

sealed class SeriesDetailState {
  const SeriesDetailState();
}

final class SeriesDetailLoading extends SeriesDetailState {
  const SeriesDetailLoading();
}

final class SeriesDetailLoaded extends SeriesDetailState {
  const SeriesDetailLoaded(this.detail);

  final SeriesDetail detail;
}

final class SeriesDetailError extends SeriesDetailState {
  const SeriesDetailError(this.message);

  final String message;
}

/// Loads the full series payload (seasons + episodes-by-season) once —
/// the seasons and episodes pages both read from this same cubit instance
/// rather than re-fetching per screen.
class SeriesDetailCubit extends Cubit<SeriesDetailState> {
  SeriesDetailCubit(this._getSeriesDetail) : super(const SeriesDetailLoading());

  final GetSeriesDetailUseCase _getSeriesDetail;

  Future<void> load(SeriesShow show) async {
    emit(const SeriesDetailLoading());
    final result = await _getSeriesDetail(show).run();
    result.fold(
      (failure) => emit(SeriesDetailError(failure.message)),
      (detail) => emit(SeriesDetailLoaded(detail)),
    );
  }
}
