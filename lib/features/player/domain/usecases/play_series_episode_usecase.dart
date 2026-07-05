import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../series/domain/entities/series_episode.dart';
import '../../../series/domain/repositories/series_repository.dart';
import '../entities/playback_engine_choice.dart';
import '../entities/playback_source.dart';

/// Episodes are file-based like VOD — same engine-choice-by-extension logic
/// as [PlayVodItemUseCase], sourced from [SeriesRepository] instead.
class PlaySeriesEpisodeUseCase {
  const PlaySeriesEpisodeUseCase(this._repository);

  final SeriesRepository _repository;

  TaskEither<Failure, PlaybackEngineChoice> call(SeriesEpisode episode) {
    return _repository.getEpisodeStreamUrl(episode).map((url) {
      final extension = episode.containerExtension?.toLowerCase();
      final kind = engineKindForContainerExtension(extension);
      return PlaybackEngineChoice(kind, PlaybackSource(url: url, containerExtension: extension));
    });
  }
}
