import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../../player/presentation/pages/player_page.dart';
import '../../../series/domain/entities/series_show.dart';
import '../../../series/presentation/pages/series_seasons_page.dart';
import '../../../vod/domain/entities/vod_item.dart';
import '../../../vod/presentation/pages/vod_detail_page.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/search_all_usecase.dart';
import '../bloc/search_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(SearchResult result) {
    final page = switch (result.type) {
      SearchResultType.live => PlayerPage(
          channel: LiveChannel(
            id: result.id,
            name: result.name,
            categoryId: result.categoryId,
            streamIcon: result.streamIcon,
          ),
        ),
      SearchResultType.vod => VodDetailPage(
          item: VodItem(
            id: result.id,
            name: result.name,
            categoryId: result.categoryId,
            streamIcon: result.streamIcon,
          ),
        ),
      SearchResultType.series => SeriesSeasonsPage(
          show: SeriesShow(
            id: result.id,
            name: result.name,
            categoryId: result.categoryId,
            cover: result.streamIcon,
          ),
        ),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBloc(getIt<SearchAllUseCase>()),
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search live TV, movies, series…',
              border: InputBorder.none,
            ),
            onChanged: (query) => context.read<SearchBloc>().add(SearchQueryChanged(query)),
          ),
        ),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            return switch (state) {
              SearchInitial() => const Center(child: Text('Start typing to search.')),
              SearchLoading() => const Center(child: CircularProgressIndicator()),
              SearchError(message: final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context
                            .read<SearchBloc>()
                            .add(SearchQueryChanged(_controller.text)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              SearchLoaded(results: final results) => results.isEmpty
                  ? const Center(child: Text('No results.'))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return ListTile(
                          leading: Icon(switch (result.type) {
                            SearchResultType.live => Icons.live_tv,
                            SearchResultType.vod => Icons.movie,
                            SearchResultType.series => Icons.tv,
                          }),
                          title: Text(result.name),
                          onTap: () => _open(result),
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
