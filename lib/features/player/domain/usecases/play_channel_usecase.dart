import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../../live_tv/domain/repositories/live_tv_repository.dart';
import '../entities/playback_engine_choice.dart';
import '../repositories/playback_engine_selector.dart';

/// Resolves both candidate URLs and defers to [PlaybackEngineSelector] to
/// probe `.m3u8` and fall back to `.ts`/mpv per PLAN.md's player strategy.
class PlayChannelUseCase {
  const PlayChannelUseCase(this._repository, this._selector);

  final LiveTvRepository _repository;
  final PlaybackEngineSelector _selector;

  TaskEither<Failure, PlaybackEngineChoice> call(LiveChannel channel) {
    return _repository.getStreamUrl(channel, format: 'm3u8').flatMap(
      (m3u8Url) => _repository.getStreamUrl(channel, format: 'ts').flatMap(
        (tsUrl) => TaskEither<Failure, PlaybackEngineChoice>.tryCatch(
          () => _selector.choose(m3u8Url: m3u8Url, tsUrl: tsUrl),
          (error, _) => PlaybackFailure(error.toString()),
        ),
      ),
    );
  }
}
