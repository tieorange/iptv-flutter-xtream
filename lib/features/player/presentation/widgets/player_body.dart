import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/engines/av_player_controller.dart';
import '../../data/engines/mpv_player_controller.dart';
import '../cubit/player_cubit.dart';
import 'fallback_engine_badge.dart';
import 'player_chrome_media_kit.dart';
import 'player_chrome_video_player.dart';

/// Shared state-to-UI mapping for the player screen, reused by the live-TV
/// and VOD/series player pages so they don't duplicate the engine switch.
class PlayerBody extends StatelessWidget {
  const PlayerBody({super.key, required this.onRetry, this.castButton});

  final VoidCallback onRetry;

  /// Supplied by [PlayerPage] for live TV only — VOD/series don't wire
  /// Chromecast in this pass. Not engine-gated like [AirplayButton]: casting
  /// works the same regardless of which local engine is active.
  final Widget? castButton;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        return switch (state) {
          PlayerLoading() => const CircularProgressIndicator(),
          PlayerError(message: final message) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          PlayerReady(controller: final controller, isFallbackEngine: final fallback, isLive: final isLive) =>
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                switch (controller) {
                  AvPlayerController() =>
                    PlayerChromeVideoPlayer(controller: controller, isLive: isLive),
                  MpvPlayerController() => PlayerChromeMediaKit(controller: controller),
                  _ => const Text('Unsupported playback engine'),
                },
                if (fallback)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: FallbackEngineBadge(),
                  ),
                if (castButton != null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: castButton,
                    ),
                  ),
              ],
            ),
        };
      },
    );
  }
}
