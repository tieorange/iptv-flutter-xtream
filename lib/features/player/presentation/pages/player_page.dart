import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../epg/presentation/widgets/now_next_strip.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../cubit/player_cubit.dart';
import '../widgets/player_body.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key, required this.channel});

  final LiveChannel channel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlayerCubit>()..playChannel(channel),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text(channel.name)),
            body: Column(
              children: [
                Expanded(
                  child: Center(
                    child: PlayerBody(
                      onRetry: () => context.read<PlayerCubit>().playChannel(channel),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: NowNextStrip(channelId: channel.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
