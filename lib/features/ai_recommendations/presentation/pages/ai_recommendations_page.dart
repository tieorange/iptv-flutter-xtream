import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../../domain/entities/ai_recommendation.dart';
import '../../domain/usecases/get_top_picks_usecase.dart';
import '../cubit/ai_recommendations_cubit.dart';
import '../widgets/ai_pick_tile.dart';

class AiRecommendationsPage extends StatefulWidget {
  const AiRecommendationsPage({super.key});

  @override
  State<AiRecommendationsPage> createState() => _AiRecommendationsPageState();
}

class _AiRecommendationsPageState extends State<AiRecommendationsPage> {
  late final AiRecommendationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AiRecommendationsCubit(getIt<GetTopPicksUseCase>());
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: const Text('Top 40 Now'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _cubit.load,
            ),
          ],
        ),
        body: BlocBuilder<AiRecommendationsCubit, AiRecommendationsState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (state) {
                AiRecommendationsLoading() => const _LoadingView(key: ValueKey('loading')),
                AiRecommendationsError(message: final message) => _ErrorView(
                    key: const ValueKey('error'),
                    message: message,
                    onRetry: _cubit.load,
                  ),
                AiRecommendationsLoaded(picks: final picks) => picks.isEmpty
                    ? const _EmptyView(key: ValueKey('empty'))
                    : _PicksListView(key: const ValueKey('loaded'), picks: picks),
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 48.0, color: colors.primary),
            const SizedBox(height: 24.0),
            const CircularProgressIndicator(),
            const SizedBox(height: 24.0),
            Text(
              'Scanning what\'s on now across English, Russian, Polish, and\n'
              'Ukrainian channels — this can take up to 30 seconds.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.0, color: colors.error),
            const SizedBox(height: 16.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24.0),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tv_off, size: 48.0, color: colors.onSurfaceVariant),
            const SizedBox(height: 16.0),
            Text('No picks right now.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PicksListView extends StatelessWidget {
  const _PicksListView({super.key, required this.picks});

  final List<AiRecommendation> picks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      itemCount: picks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.primary, size: 20.0),
                const SizedBox(width: 8.0),
                Text(
                  '${picks.length} AI-curated picks, live right now',
                  style: textTheme.titleSmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        final pick = picks[index - 1];
        return AiPickTile(
          pick: pick,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PlayerPage(
              channel: LiveChannel(id: pick.channelId, name: pick.channelName, categoryId: 0),
            ),
          )),
        );
      },
    );
  }
}
