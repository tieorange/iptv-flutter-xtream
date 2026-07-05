import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/vod_item.dart';
import '../repositories/vod_repository.dart';

class GetVodItemsUseCase {
  const GetVodItemsUseCase(this._repository);

  final VodRepository _repository;

  TaskEither<Failure, List<VodItem>> call(int categoryId) =>
      _repository.getItems(categoryId);
}
