import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/live_category.dart';
import '../../domain/usecases/get_live_channels_usecase.dart';
import '../cubit/live_channels_cubit.dart';
import '../widgets/channel_list_tile.dart';

class LiveChannelsPage extends StatelessWidget {
  const LiveChannelsPage({super.key, required this.categoryId, this.category});

  final int categoryId;
  final LiveCategory? category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveChannelsCubit(getIt<GetLiveChannelsUseCase>())..load(categoryId),
      child: Scaffold(
        appBar: AppBar(title: Text(category?.name ?? 'Channels')),
        body: BlocBuilder<LiveChannelsCubit, LiveChannelsState>(
          builder: (context, state) {
            return switch (state) {
              LiveChannelsLoading() => const Center(child: CircularProgressIndicator()),
              LiveChannelsError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<LiveChannelsCubit>().load(categoryId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              LiveChannelsLoaded(channels: final channels) => channels.isEmpty
                  ? const Center(child: Text('No channels in this category.'))
                  : ListView.builder(
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        return ChannelListTile(
                          channel: channel,
                          onTap: () => context.pushNamed(
                            'playerLive',
                            pathParameters: {'channelId': channel.id.toString()},
                            extra: channel,
                          ),
                        );
                      },
                    ),
            };
          },
        ),
      ),
    );
  }
}
