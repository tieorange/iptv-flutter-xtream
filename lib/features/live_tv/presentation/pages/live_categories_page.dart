import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/live_category.dart';
import '../../domain/usecases/get_live_categories_usecase.dart';
import '../cubit/live_categories_cubit.dart';

class LiveCategoriesPage extends StatelessWidget {
  const LiveCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveCategoriesCubit(getIt<GetLiveCategoriesUseCase>())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Live TV')),
        body: BlocBuilder<LiveCategoriesCubit, LiveCategoriesState>(
          builder: (context, state) {
            return switch (state) {
              LiveCategoriesLoading() => const Center(child: CircularProgressIndicator()),
              LiveCategoriesError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<LiveCategoriesCubit>().load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              LiveCategoriesLoaded(categories: final categories) => categories.isEmpty
                  ? const Center(child: Text('No live categories.'))
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final LiveCategory category = categories[index];
                        return ListTile(
                          title: Text(category.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.pushNamed(
                            'liveChannels',
                            pathParameters: {'categoryId': category.id.toString()},
                            extra: category,
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
