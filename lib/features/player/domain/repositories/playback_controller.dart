import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/playback_source.dart';

/// One instance per active playback session — never a get_it singleton.
/// Implementations wrap a concrete engine (AVPlayer via `video_player` for
/// M2/M3, mpv via `media_kit` added in M3) behind the same contract so
/// [PlayerCubit] doesn't need to know which engine is active.
abstract interface class PlaybackController {
  TaskEither<PlaybackFailure, Unit> initialize(PlaybackSource source);

  Future<void> dispose();
}
