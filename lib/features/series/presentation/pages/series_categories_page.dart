import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/series_category.dart';
import '../../domain/usecases/get_series_categories_usecase.dart';
import '../cubit/series_categories_cubit.dart';

class SeriesCategoriesPage extends StatelessWidget {
  const SeriesCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SeriesCategoriesCubit(getIt<GetSeriesCategoriesUseCase>())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Series')),
        body: BlocBuilder<SeriesCategoriesCubit, SeriesCategoriesState>(
          builder: (context, state) {
            return switch (state) {
              SeriesCategoriesLoading() => const Center(child: CircularProgressIndicator()),
              SeriesCategoriesError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<SeriesCategoriesCubit>().load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              SeriesCategoriesLoaded(categories: final categories) => categories.isEmpty
                  ? const Center(child: Text('No series categories.'))
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final SeriesCategory category = categories[index];
                        return ListTile(
                          title: Text(category.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.pushNamed(
                            'seriesList',
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
