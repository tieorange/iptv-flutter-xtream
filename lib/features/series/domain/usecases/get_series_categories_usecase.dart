import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/series_category.dart';
import '../repositories/series_repository.dart';

class GetSeriesCategoriesUseCase {
  const GetSeriesCategoriesUseCase(this._repository);

  final SeriesRepository _repository;

  TaskEither<Failure, List<SeriesCategory>> call() => _repository.getCategories();
}
