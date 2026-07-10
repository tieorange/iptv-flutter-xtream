import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../../live_tv/domain/repositories/live_tv_repository.dart';
import '../../data/probes/hls_availability_probe.dart';
import '../entities/cast_media_request.dart';

/// Resolves the best castable URL for a live channel. Unlike
/// [PlaybackEngineSelector]'s AV/mpv split, there's no "no route" outcome
/// here to guard against: Chromecast's receiver decodes raw MPEG-TS
/// natively, so the `.m3u8` probe is only consulted to prefer proper
/// adaptive HLS when it's genuinely available — a failed/negative probe
/// still leaves a fully castable `.ts` fallback, never a dead end.
class CastChannelUseCase {
  const CastChannelUseCase(this._repository, this._probe);

  final LiveTvRepository _repository;
  final HlsAvailabilityProbe _probe;

  TaskEither<Failure, CastMediaRequest> call(LiveChannel channel) {
    return _repository.getStreamUrl(channel, format: 'm3u8').flatMap(
      (m3u8Url) => _repository.getStreamUrl(channel, format: 'ts').flatMap(
        (tsUrl) => TaskEither<Failure, CastMediaRequest>.tryCatch(
          () async {
            final hlsAvailable = await _probe.isAvailable(m3u8Url);
            return hlsAvailable
                ? CastMediaRequest(
                    url: m3u8Url,
                    container: CastStreamContainer.hls,
                    title: channel.name,
                  )
                : CastMediaRequest(
                    url: tsUrl,
                    container: CastStreamContainer.mpegTs,
                    title: channel.name,
                  );
          },
          (error, _) => PlaybackFailure(error.toString()),
        ),
      ),
    );
  }
}
