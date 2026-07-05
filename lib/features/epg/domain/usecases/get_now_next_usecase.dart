import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/epg_program.dart';
import '../repositories/epg_repository.dart';

class GetNowNextUseCase {
  const GetNowNextUseCase(this._repository);

  final EpgRepository _repository;

  TaskEither<Failure, List<EpgProgram>> call(int channelId) =>
      _repository.getNowNext(channelId);
}
