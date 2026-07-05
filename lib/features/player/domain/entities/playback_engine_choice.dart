import 'playback_source.dart';

enum PlaybackEngineKind { av, mpv }

class PlaybackEngineChoice {
  const PlaybackEngineChoice(this.kind, this.source);

  final PlaybackEngineKind kind;
  final PlaybackSource source;
}
