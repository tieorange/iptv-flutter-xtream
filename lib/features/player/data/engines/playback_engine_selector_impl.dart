import '../../../../core/logging/app_talker.dart';
import '../../domain/entities/playback_engine_choice.dart';
import '../../domain/entities/playback_source.dart';
import '../../domain/repositories/playback_engine_selector.dart';
import '../probes/hls_availability_probe.dart';

/// This is the one piece of business logic worth a dedicated unit test —
/// no real player should be involved (see
/// test/features/player/data/engines/playback_engine_selector_test.dart).
class PlaybackEngineSelectorImpl implements PlaybackEngineSelector {
  PlaybackEngineSelectorImpl(this._probe);

  final HlsAvailabilityProbe _probe;

  @override
  Future<PlaybackEngineChoice> choose({
    required String m3u8Url,
    required String tsUrl,
  }) async {
    final hlsAvailable = await _probe.isAvailable(m3u8Url);
    if (hlsAvailable) {
      appTalker.info('PlaybackEngineSelector: HLS available, choosing AV engine');
      return PlaybackEngineChoice(
        PlaybackEngineKind.av,
        PlaybackSource(url: m3u8Url, containerExtension: 'm3u8'),
      );
    }
    appTalker.info('PlaybackEngineSelector: HLS unavailable, falling back to mpv engine');
    return PlaybackEngineChoice(
      PlaybackEngineKind.mpv,
      PlaybackSource(url: tsUrl, containerExtension: 'ts'),
    );
  }
}
