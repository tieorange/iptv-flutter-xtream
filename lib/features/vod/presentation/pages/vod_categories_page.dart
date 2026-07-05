import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/vod_category.dart';
import '../../domain/usecases/get_vod_categories_usecase.dart';
import '../cubit/vod_categories_cubit.dart';

class VodCategoriesPage extends StatelessWidget {
  const VodCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VodCategoriesCubit(getIt<GetVodCategoriesUseCase>())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Movies')),
        body: BlocBuilder<VodCategoriesCubit, VodCategoriesState>(
          builder: (context, state) {
            return switch (state) {
              VodCategoriesLoading() => const Center(child: CircularProgressIndicator()),
              VodCategoriesError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<VodCategoriesCubit>().load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              VodCategoriesLoaded(categories: final categories) => categories.isEmpty
                  ? const Center(child: Text('No VOD categories.'))
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final VodCategory category = categories[index];
                        return ListTile(
                          title: Text(category.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.pushNamed(
                            'vodItems',
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
