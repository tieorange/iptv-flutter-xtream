import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/vod_category.dart';
import '../../domain/entities/vod_item.dart';
import '../../domain/usecases/get_vod_items_usecase.dart';
import '../cubit/vod_items_cubit.dart';

class VodItemsPage extends StatelessWidget {
  const VodItemsPage({super.key, required this.categoryId, this.category});

  final int categoryId;
  final VodCategory? category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VodItemsCubit(getIt<GetVodItemsUseCase>())..load(categoryId),
      child: Scaffold(
        appBar: AppBar(title: Text(category?.name ?? 'Movies')),
        body: BlocBuilder<VodItemsCubit, VodItemsState>(
          builder: (context, state) {
            return switch (state) {
              VodItemsLoading() => const Center(child: CircularProgressIndicator()),
              VodItemsError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<VodItemsCubit>().load(categoryId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              VodItemsLoaded(items: final items) => items.isEmpty
                  ? const Center(child: Text('No movies in this category.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2 / 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final VodItem item = items[index];
                        return GestureDetector(
                          onTap: () => context.pushNamed(
                            'vodDetail',
                            pathParameters: {
                              'categoryId': categoryId.toString(),
                              'itemId': item.id.toString(),
                            },
                            extra: item,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: item.streamIcon == null || item.streamIcon!.isEmpty
                                    ? const ColoredBox(
                                        color: Colors.black12,
                                        child: Icon(Icons.movie),
                                      )
                                    : Image.network(
                                        item.streamIcon!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const ColoredBox(
                                          color: Colors.black12,
                                          child: Icon(Icons.movie),
                                        ),
                                      ),
                              ),
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
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
