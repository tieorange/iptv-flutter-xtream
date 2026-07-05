import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../data/engines/mpv_player_controller.dart';

/// media_kit's own control chrome for the mpv fallback engine. Kept as a
/// separate widget tree from [PlayerChromeVideoPlayer] since chewie only
/// wraps `video_player` and can't drive media_kit's player.
class PlayerChromeMediaKit extends StatelessWidget {
  const PlayerChromeMediaKit({super.key, required this.controller});

  final MpvPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Video(controller: controller.videoController);
  }
}
