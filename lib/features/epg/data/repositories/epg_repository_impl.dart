import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/url_scrubber.dart';
import '../../domain/entities/epg_program.dart';
import '../../domain/repositories/epg_repository.dart';
import '../datasources/epg_remote_datasource.dart';

class EpgRepositoryImpl implements EpgRepository {
  EpgRepositoryImpl(this._remote);

  final EpgRemoteDataSource _remote;

  @override
  TaskEither<Failure, List<EpgProgram>> getNowNext(int channelId) {
    return TaskEither.tryCatch(() => _remote.getNowNext(channelId), _toFailure);
  }

  Failure _toFailure(Object error, StackTrace _) {
    if (error is Failure) return error;
    return UnknownFailure(scrubMessage(error.toString()));
  }
}
