import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/url_scrubber.dart';
import '../../domain/entities/series_category.dart';
import '../../domain/entities/series_detail.dart';
import '../../domain/entities/series_episode.dart';
import '../../domain/entities/series_show.dart';
import '../../domain/repositories/series_repository.dart';
import '../datasources/series_remote_datasource.dart';

class SeriesRepositoryImpl implements SeriesRepository {
  SeriesRepositoryImpl(this._remote);

  final SeriesRemoteDataSource _remote;

  @override
  TaskEither<Failure, List<SeriesCategory>> getCategories() {
    return TaskEither.tryCatch(() => _remote.getCategories(), _toFailure);
  }

  @override
  TaskEither<Failure, List<SeriesShow>> getSeries(int categoryId) {
    return TaskEither.tryCatch(() => _remote.getSeries(categoryId), _toFailure);
  }

  @override
  TaskEither<Failure, List<SeriesShow>> getAllSeries() {
    return TaskEither.tryCatch(() => _remote.getAllSeries(), _toFailure);
  }

  @override
  TaskEither<Failure, SeriesDetail> getSeriesDetail(SeriesShow show) {
    return TaskEither.tryCatch(() => _remote.getSeriesDetail(show), _toFailure);
  }

  @override
  TaskEither<Failure, String> getEpisodeStreamUrl(SeriesEpisode episode) {
    return TaskEither.tryCatch(
      () async => _remote.getEpisodeStreamUrl(episode.id, episode.containerExtension ?? 'mp4'),
      _toFailure,
    );
  }

  Failure _toFailure(Object error, StackTrace _) {
    if (error is Failure) return error;
    return UnknownFailure(scrubMessage(error.toString()));
  }
}
