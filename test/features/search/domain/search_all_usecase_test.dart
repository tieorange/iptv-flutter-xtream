import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/live_tv/domain/entities/live_channel.dart';
import 'package:iptv/features/live_tv/domain/repositories/live_tv_repository.dart';
import 'package:iptv/features/search/domain/entities/search_result.dart';
import 'package:iptv/features/search/domain/usecases/search_all_usecase.dart';
import 'package:iptv/features/series/domain/entities/series_show.dart';
import 'package:iptv/features/series/domain/repositories/series_repository.dart';
import 'package:iptv/features/vod/domain/entities/vod_item.dart';
import 'package:iptv/features/vod/domain/repositories/vod_repository.dart';

class _MockLiveTvRepository extends Mock implements LiveTvRepository {}

class _MockVodRepository extends Mock implements VodRepository {}

class _MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  late _MockLiveTvRepository liveTv;
  late _MockVodRepository vod;
  late _MockSeriesRepository series;
  late SearchAllUseCase useCase;

  setUp(() {
    liveTv = _MockLiveTvRepository();
    vod = _MockVodRepository();
    series = _MockSeriesRepository();
    useCase = SearchAllUseCase(liveTv, vod, series);

    when(() => liveTv.getAllChannels()).thenReturn(TaskEither.right([
      const LiveChannel(id: 1, name: 'BBC News', categoryId: 1),
      const LiveChannel(id: 2, name: 'ESPN', categoryId: 1),
    ]));
    when(() => vod.getAllItems()).thenReturn(TaskEither.right([
      const VodItem(id: 10, name: 'BBC Documentary', categoryId: 1),
    ]));
    when(() => series.getAllSeries()).thenReturn(TaskEither.right([
      const SeriesShow(id: 20, name: 'The Wire', categoryId: 1),
    ]));
  });

  test('empty query returns no results without hitting repositories', () async {
    final result = await useCase('').run();

    expect(result, Either<Failure, List<SearchResult>>.right(const []));
    verifyNever(() => liveTv.getAllChannels());
  });

  test('filters across all three sources, case-insensitively', () async {
    final result = await useCase('bbc').run();

    final names = result.getOrElse((_) => []).map((r) => r.name).toSet();
    expect(names, {'BBC News', 'BBC Documentary'});
  });

  test('caches after first load — second search does not re-fetch', () async {
    await useCase('bbc').run();
    await useCase('espn').run();

    verify(() => liveTv.getAllChannels()).called(1);
    verify(() => vod.getAllItems()).called(1);
    verify(() => series.getAllSeries()).called(1);
  });
}
