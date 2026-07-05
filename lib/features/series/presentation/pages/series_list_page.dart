import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/series_category.dart';
import '../../domain/entities/series_show.dart';
import '../../domain/usecases/get_series_usecase.dart';
import '../cubit/series_list_cubit.dart';

class SeriesListPage extends StatelessWidget {
  const SeriesListPage({super.key, required this.categoryId, this.category});

  final int categoryId;
  final SeriesCategory? category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SeriesListCubit(getIt<GetSeriesUseCase>())..load(categoryId),
      child: Scaffold(
        appBar: AppBar(title: Text(category?.name ?? 'Series')),
        body: BlocBuilder<SeriesListCubit, SeriesListState>(
          builder: (context, state) {
            return switch (state) {
              SeriesListLoading() => const Center(child: CircularProgressIndicator()),
              SeriesListError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<SeriesListCubit>().load(categoryId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              SeriesListLoaded(series: final series) => series.isEmpty
                  ? const Center(child: Text('No series in this category.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2 / 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: series.length,
                      itemBuilder: (context, index) {
                        final SeriesShow show = series[index];
                        return GestureDetector(
                          onTap: () => context.pushNamed(
                            'seriesSeasons',
                            pathParameters: {
                              'categoryId': categoryId.toString(),
                              'seriesId': show.id.toString(),
                            },
                            extra: show,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: show.cover == null || show.cover!.isEmpty
                                    ? const ColoredBox(
                                        color: Colors.black12,
                                        child: Icon(Icons.tv),
                                      )
                                    : Image.network(
                                        show.cover!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const ColoredBox(
                                          color: Colors.black12,
                                          child: Icon(Icons.tv),
                                        ),
                                      ),
                              ),
                              Text(
                                show.name,
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
