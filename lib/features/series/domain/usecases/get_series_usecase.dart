import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/series_show.dart';
import '../repositories/series_repository.dart';

class GetSeriesUseCase {
  const GetSeriesUseCase(this._repository);

  final SeriesRepository _repository;

  TaskEither<Failure, List<SeriesShow>> call(int categoryId) =>
      _repository.getSeries(categoryId);
}
