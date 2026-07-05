import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/series_detail.dart';
import '../entities/series_show.dart';
import '../repositories/series_repository.dart';

class GetSeriesDetailUseCase {
  const GetSeriesDetailUseCase(this._repository);

  final SeriesRepository _repository;

  TaskEither<Failure, SeriesDetail> call(SeriesShow show) =>
      _repository.getSeriesDetail(show);
}
