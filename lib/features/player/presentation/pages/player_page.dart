import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../data/engines/av_player_controller.dart';
import '../../data/engines/mpv_player_controller.dart';
import '../../domain/usecases/play_channel_usecase.dart';
import '../cubit/player_cubit.dart';
import '../widgets/fallback_engine_badge.dart';
import '../widgets/player_chrome_media_kit.dart';
import '../widgets/player_chrome_video_player.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key, required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlayerCubit(getIt<PlayChannelUseCase>())..playChannel(channel),
      child: Scaffold(
        appBar: AppBar(title: Text(channel.name)),
        body: Center(
          child: BlocBuilder<PlayerCubit, PlayerState>(
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
                        FilledButton(
                          onPressed: () => context.read<PlayerCubit>().playChannel(channel),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                PlayerReady(controller: final controller, isFallbackEngine: final fallback) => Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      switch (controller) {
                        AvPlayerController() => PlayerChromeVideoPlayer(controller: controller),
                        MpvPlayerController() => PlayerChromeMediaKit(controller: controller),
                        _ => const Text('Unsupported playback engine'),
                      },
                      if (fallback)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: FallbackEngineBadge(),
                        ),
                    ],
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}
