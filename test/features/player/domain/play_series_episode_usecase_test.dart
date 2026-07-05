import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/features/player/domain/entities/playback_engine_choice.dart';
import 'package:iptv/features/player/domain/usecases/play_series_episode_usecase.dart';
import 'package:iptv/features/series/domain/entities/series_episode.dart';
import 'package:iptv/features/series/domain/repositories/series_repository.dart';

class _MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  late _MockSeriesRepository repository;
  late PlaySeriesEpisodeUseCase useCase;

  setUp(() {
    repository = _MockSeriesRepository();
    useCase = PlaySeriesEpisodeUseCase(repository);
  });

  test('picks the AV engine for mp4 episodes', () async {
    const episode = SeriesEpisode(id: 1, title: 'S01E01', seasonNumber: 1, containerExtension: 'mp4');
    when(() => repository.getEpisodeStreamUrl(episode))
        .thenReturn(TaskEither.right('http://x/1.mp4'));

    final result = await useCase(episode).run();

    expect(result.getOrElse((_) => throw Exception()).kind, PlaybackEngineKind.av);
  });

  test('falls back to mpv for mkv episodes', () async {
    const episode = SeriesEpisode(id: 2, title: 'S01E02', seasonNumber: 1, containerExtension: 'mkv');
    when(() => repository.getEpisodeStreamUrl(episode))
        .thenReturn(TaskEither.right('http://x/2.mkv'));

    final result = await useCase(episode).run();

    expect(result.getOrElse((_) => throw Exception()).kind, PlaybackEngineKind.mpv);
  });
}
