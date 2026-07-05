import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../player/presentation/cubit/player_cubit.dart';
import '../../../player/presentation/widgets/player_body.dart';
import '../../domain/entities/series_episode.dart';

class SeriesPlayerPage extends StatelessWidget {
  const SeriesPlayerPage({super.key, required this.episode});

  final SeriesEpisode episode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlayerCubit>()..playEpisode(episode),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text(episode.title)),
            body: Center(
              child: PlayerBody(
                onRetry: () => context.read<PlayerCubit>().playEpisode(episode),
              ),
            ),
          );
        },
      ),
    );
  }
}
