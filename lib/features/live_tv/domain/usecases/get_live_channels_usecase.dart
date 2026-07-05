import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/live_channel.dart';
import '../repositories/live_tv_repository.dart';

class GetLiveChannelsUseCase {
  const GetLiveChannelsUseCase(this._repository);

  final LiveTvRepository _repository;

  TaskEither<Failure, List<LiveChannel>> call(int categoryId) =>
      _repository.getChannels(categoryId);
}
