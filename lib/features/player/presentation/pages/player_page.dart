import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../epg/presentation/widgets/now_next_strip.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../domain/entities/cast_session_state.dart';
import '../cubit/cast_cubit.dart';
import '../cubit/player_cubit.dart';
import '../widgets/cast_button.dart';
import '../widgets/player_body.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key, required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<PlayerCubit>()..playChannel(channel)),
        BlocProvider(create: (_) => getIt<CastCubit>()),
      ],
      child: Builder(
        builder: (context) {
          return BlocListener<CastCubit, CastSessionState>(
            // Casting is engine-agnostic: pause whichever local engine
            // (AV or mpv) is currently active while the TV is playing, and
            // resume it once the cast session ends.
            listener: (context, castState) {
              final playerState = context.read<PlayerCubit>().state;
              if (playerState is! PlayerReady) return;
              if (castState is CastConnected) {
                playerState.controller.pause();
              } else if (castState is CastDisconnected) {
                playerState.controller.resume();
              }
            },
            child: Scaffold(
              appBar: AppBar(title: Text(channel.name)),
              body: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: PlayerBody(
                        onRetry: () =>
                            context.read<PlayerCubit>().playChannel(channel),
                        castButton: CastButton(channel: channel),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: NowNextStrip(channelId: channel.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
