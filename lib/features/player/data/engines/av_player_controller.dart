import 'package:fpdart/fpdart.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_talker.dart';
import '../../../../core/utils/url_scrubber.dart';
import '../../domain/entities/playback_source.dart';
import '../../domain/repositories/playback_controller.dart';

/// AVPlayer-backed engine (via `video_player`) — the path that gets
/// AirPlay/PiP/lock-screen controls per PLAN.md. Always used for `.m3u8`
/// sources; the raw-`.ts` fallback to `MpvPlayerController` lands in M3.
class AvPlayerController implements PlaybackController {
  VideoPlayerController? _controller;

  VideoPlayerController get videoPlayerController {
    final controller = _controller;
    if (controller == null) {
      throw StateError('AvPlayerController.initialize must be called first.');
    }
    return controller;
  }

  @override
  TaskEither<PlaybackFailure, Unit> initialize(PlaybackSource source) {
    appTalker.info('AvPlayerController: opening ${scrubMessage(source.url)}');
    return TaskEither.tryCatch(
      () async {
        final controller = VideoPlayerController.networkUrl(Uri.parse(source.url));
        await controller.initialize();
        await controller.play();
        _controller = controller;
        return unit;
      },
      (error, stackTrace) {
        appTalker.error(
          'AvPlayerController initialization failed: ${scrubMessage(error.toString())}',
          error,
          stackTrace,
        );
        return PlaybackFailure(scrubMessage(error.toString()));
      },
    );
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> resume() async {
    await _controller?.play();
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
