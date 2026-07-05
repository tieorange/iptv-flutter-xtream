import 'playback_source.dart';

enum PlaybackEngineKind { av, mpv }

class PlaybackEngineChoice {
  const PlaybackEngineChoice(this.kind, this.source);

  final PlaybackEngineKind kind;
  final PlaybackSource source;
}

/// Shared by VOD and series playback (both direct-file/already-HLS content
/// per PLAN.md): AVPlayer plays these containers natively; anything else
/// (mkv, avi, raw ts, ...) goes to the mpv fallback engine. Unlike live TV,
/// this is a pure lookup on the panel-reported extension, not a probe.
const _avSupportedExtensions = {'mp4', 'mov', 'm4v', 'm3u8'};

PlaybackEngineKind engineKindForContainerExtension(String? extension) {
  return _avSupportedExtensions.contains(extension?.toLowerCase())
      ? PlaybackEngineKind.av
      : PlaybackEngineKind.mpv;
}
