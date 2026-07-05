import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/series_category.dart';
import '../entities/series_detail.dart';
import '../entities/series_episode.dart';
import '../entities/series_show.dart';

abstract interface class SeriesRepository {
  TaskEither<Failure, List<SeriesCategory>> getCategories();

  TaskEither<Failure, List<SeriesShow>> getSeries(int categoryId);

  /// All series across every category — used by search.
  TaskEither<Failure, List<SeriesShow>> getAllSeries();

  TaskEither<Failure, SeriesDetail> getSeriesDetail(SeriesShow show);

  /// Episodes are file-based like VOD — [episode.containerExtension]
  /// decides the engine, never assume HLS.
  TaskEither<Failure, String> getEpisodeStreamUrl(SeriesEpisode episode);
}
