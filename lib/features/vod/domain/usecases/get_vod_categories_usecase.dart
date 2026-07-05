import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/vod_category.dart';
import '../repositories/vod_repository.dart';

class GetVodCategoriesUseCase {
  const GetVodCategoriesUseCase(this._repository);

  final VodRepository _repository;

  TaskEither<Failure, List<VodCategory>> call() => _repository.getCategories();
}
