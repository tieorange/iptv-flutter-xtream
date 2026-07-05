import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/url_scrubber.dart';
import '../../domain/entities/live_category.dart';
import '../../domain/entities/live_channel.dart';
import '../../domain/repositories/live_tv_repository.dart';
import '../datasources/live_tv_remote_datasource.dart';

class LiveTvRepositoryImpl implements LiveTvRepository {
  LiveTvRepositoryImpl(this._remote);

  final LiveTvRemoteDataSource _remote;

  @override
  TaskEither<Failure, List<LiveCategory>> getCategories() {
    return TaskEither.tryCatch(() => _remote.getCategories(), _toFailure);
  }

  @override
  TaskEither<Failure, List<LiveChannel>> getChannels(int categoryId) {
    return TaskEither.tryCatch(
      () => _remote.getChannels(categoryId),
      _toFailure,
    );
  }

  @override
  TaskEither<Failure, List<LiveChannel>> getAllChannels() {
    return TaskEither.tryCatch(() => _remote.getAllChannels(), _toFailure);
  }

  @override
  TaskEither<Failure, String> getStreamUrl(LiveChannel channel, {String format = 'm3u8'}) {
    return TaskEither.tryCatch(
      () async => _remote.getStreamUrl(channel.id, format),
      _toFailure,
    );
  }

  Failure _toFailure(Object error, StackTrace _) {
    if (error is Failure) return error;
    return UnknownFailure(scrubMessage(error.toString()));
  }
}
