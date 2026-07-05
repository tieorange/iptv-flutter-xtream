import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

import '../../data/engines/av_player_controller.dart';
import 'airplay_button.dart';

/// Chewie-based chrome for the AVPlayer engine. The mpv fallback engine
/// (M3) gets its own `media_kit_video`-based chrome widget — chewie only
/// wraps `video_player`, it can't drive media_kit's player.
class PlayerChromeVideoPlayer extends StatefulWidget {
  const PlayerChromeVideoPlayer({super.key, required this.controller});

  final AvPlayerController controller;

  @override
  State<PlayerChromeVideoPlayer> createState() => _PlayerChromeVideoPlayerState();
}

class _PlayerChromeVideoPlayerState extends State<PlayerChromeVideoPlayer> {
  late final ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _chewieController = ChewieController(
      videoPlayerController: widget.controller.videoPlayerController,
      autoPlay: true,
      isLive: true,
    );
  }

  @override
  void dispose() {
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        AspectRatio(
          aspectRatio: widget.controller.videoPlayerController.value.aspectRatio,
          child: Chewie(controller: _chewieController),
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: AirplayButton(),
        ),
      ],
    );
  }
}
