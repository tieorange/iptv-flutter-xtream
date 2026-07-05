import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/live_category.dart';
import '../repositories/live_tv_repository.dart';

class GetLiveCategoriesUseCase {
  const GetLiveCategoriesUseCase(this._repository);

  final LiveTvRepository _repository;

  TaskEither<Failure, List<LiveCategory>> call() => _repository.getCategories();
}
