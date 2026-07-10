import 'package:fpdart/fpdart.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_talker.dart';
import '../../../../core/utils/url_scrubber.dart';
import '../../domain/entities/playback_source.dart';
import '../../domain/repositories/playback_controller.dart';

/// mpv-backed fallback engine (via `media_kit`) for panels/streams that
/// don't serve working `.m3u8`. No AirPlay/PiP here — `player_page.dart`
/// hides the AirPlay button and shows the fallback badge whenever this
/// engine is active.
class MpvPlayerController implements PlaybackController {
  final Player _player = Player();
  VideoController? _videoController;

  VideoController get videoController {
    final controller = _videoController;
    if (controller == null) {
      throw StateError('MpvPlayerController.initialize must be called first.');
    }
    return controller;
  }

  @override
  TaskEither<PlaybackFailure, Unit> initialize(PlaybackSource source) {
    appTalker.info('MpvPlayerController: opening ${scrubMessage(source.url)}');
    return TaskEither.tryCatch(
      () async {
        _videoController = VideoController(_player);
        await _player.open(Media(source.url));
        return unit;
      },
      (error, stackTrace) {
        appTalker.error(
          'MpvPlayerController initialization failed: ${scrubMessage(error.toString())}',
          error,
          stackTrace,
        );
        return PlaybackFailure(scrubMessage(error.toString()));
      },
    );
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
