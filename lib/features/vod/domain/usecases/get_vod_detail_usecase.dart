import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/vod_detail.dart';
import '../entities/vod_item.dart';
import '../repositories/vod_repository.dart';

class GetVodDetailUseCase {
  const GetVodDetailUseCase(this._repository);

  final VodRepository _repository;

  TaskEither<Failure, VodDetail> call(VodItem item) => _repository.getDetail(item);
}
