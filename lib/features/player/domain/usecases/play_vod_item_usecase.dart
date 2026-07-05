import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../vod/domain/entities/vod_detail.dart';
import '../../../vod/domain/repositories/vod_repository.dart';
import '../entities/playback_engine_choice.dart';
import '../entities/playback_source.dart';

/// VOD content is usually a direct file (mp4/mkv) or already-HLS — unlike
/// live TV, there's no `.m3u8`-first probe here: the panel's
/// `container_extension` field is authoritative, so the engine choice is a
/// pure lookup rather than a network probe.
class PlayVodItemUseCase {
  const PlayVodItemUseCase(this._repository);

  final VodRepository _repository;

  TaskEither<Failure, PlaybackEngineChoice> call(VodDetail detail) {
    return _repository.getStreamUrl(detail).map((url) {
      final extension = detail.containerExtension?.toLowerCase();
      final kind = engineKindForContainerExtension(extension);
      return PlaybackEngineChoice(kind, PlaybackSource(url: url, containerExtension: extension));
    });
  }
}
