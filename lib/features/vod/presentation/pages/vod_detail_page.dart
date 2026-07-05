import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../favorites/domain/entities/favorite_item.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/entities/vod_item.dart';
import '../../domain/usecases/get_vod_detail_usecase.dart';
import '../cubit/vod_detail_cubit.dart';

class VodDetailPage extends StatelessWidget {
  const VodDetailPage({super.key, required this.item});

  final VodItem item;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VodDetailCubit(getIt<GetVodDetailUseCase>())..load(item),
      child: Scaffold(
        appBar: AppBar(
          title: Text(item.name),
          actions: [
            FavoriteButton(
              item: FavoriteItem(
                itemId: item.id,
                itemType: FavoriteItemType.vod,
                name: item.name,
                streamIcon: item.streamIcon,
              ),
            ),
          ],
        ),
        body: BlocBuilder<VodDetailCubit, VodDetailState>(
          builder: (context, state) {
            return switch (state) {
              VodDetailLoading() => const Center(child: CircularProgressIndicator()),
              VodDetailError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<VodDetailCubit>().load(item),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              VodDetailLoaded(detail: final detail) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detail.coverUrl != null && detail.coverUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(detail.coverUrl!, height: 240, fit: BoxFit.cover),
                        ),
                      const SizedBox(height: 16),
                      Text(detail.name, style: Theme.of(context).textTheme.headlineSmall),
                      if (detail.genre != null) ...[
                        const SizedBox(height: 4),
                        Text(detail.genre!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                      if (detail.description != null) ...[
                        const SizedBox(height: 12),
                        Text(detail.description!),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                        onPressed: () => context.pushNamed(
                          'playerVod',
                          pathParameters: {'itemId': detail.streamId.toString()},
                          extra: detail,
                        ),
                      ),
                    ],
                  ),
                ),
            };
          },
        ),
      ),
    );
  }
}
