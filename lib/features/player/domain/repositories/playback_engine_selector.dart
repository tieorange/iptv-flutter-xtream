import '../entities/playback_engine_choice.dart';

/// Defaults to `.m3u8` for every live stream per PLAN.md; falls back to the
/// mpv engine (fed the raw `.ts` URL) only when `.m3u8` doesn't check out.
/// The probe is an I/O concern, so the implementation lives in `data/`.
abstract interface class PlaybackEngineSelector {
  Future<PlaybackEngineChoice> choose({
    required String m3u8Url,
    required String tsUrl,
  });
}
