import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/live_tv/domain/entities/live_channel.dart';
import 'package:iptv/features/player/domain/entities/playback_engine_choice.dart';
import 'package:iptv/features/player/domain/entities/playback_source.dart';
import 'package:iptv/features/player/domain/repositories/playback_controller.dart';
import 'package:iptv/features/player/domain/usecases/play_channel_usecase.dart';
import 'package:iptv/features/player/domain/usecases/play_series_episode_usecase.dart';
import 'package:iptv/features/player/domain/usecases/play_vod_item_usecase.dart';
import 'package:iptv/features/player/presentation/cubit/player_cubit.dart';

class _MockPlayChannelUseCase extends Mock implements PlayChannelUseCase {}

class _MockPlayVodItemUseCase extends Mock implements PlayVodItemUseCase {}

class _MockPlaySeriesEpisodeUseCase extends Mock implements PlaySeriesEpisodeUseCase {}

class _MockPlaybackController extends Mock implements PlaybackController {}

void main() {
  late _MockPlayChannelUseCase playChannelUseCase;
  late _MockPlayVodItemUseCase playVodItemUseCase;
  late _MockPlaySeriesEpisodeUseCase playSeriesEpisodeUseCase;
  late _MockPlaybackController avController;
  late _MockPlaybackController mpvController;
  late PlayerCubit cubit;

  const channel = LiveChannel(id: 1, name: 'Test Channel', categoryId: 1);
  const m3u8Source = PlaybackSource(url: 'http://x/1.m3u8', containerExtension: 'm3u8');
  const tsFallback = PlaybackSource(url: 'http://x/1.ts', containerExtension: 'ts');

  setUpAll(() {
    registerFallbackValue(const PlaybackSource(url: 'http://fallback'));
  });

  setUp(() {
    playChannelUseCase = _MockPlayChannelUseCase();
    playVodItemUseCase = _MockPlayVodItemUseCase();
    playSeriesEpisodeUseCase = _MockPlaySeriesEpisodeUseCase();
    avController = _MockPlaybackController();
    mpvController = _MockPlaybackController();
    when(() => avController.dispose()).thenAnswer((_) async {});
    when(() => mpvController.dispose()).thenAnswer((_) async {});
    cubit = PlayerCubit(
      playChannelUseCase,
      playVodItemUseCase,
      playSeriesEpisodeUseCase,
      avPlayerFactory: () => avController,
      mpvPlayerFactory: () => mpvController,
    );
  });

  tearDown(() => cubit.close());

  test('falls back to the mpv engine when AV init fails and a fallback source is present', () async {
    when(() => playChannelUseCase(channel)).thenReturn(
      TaskEither.right(
        const PlaybackEngineChoice(PlaybackEngineKind.av, m3u8Source, fallback: tsFallback),
      ),
    );
    when(() => avController.initialize(m3u8Source)).thenReturn(
      TaskEither.left(const PlaybackFailure('404')),
    );
    when(() => mpvController.initialize(tsFallback)).thenReturn(
      TaskEither.right(unit),
    );

    await cubit.playChannel(channel);

    final state = cubit.state;
    expect(state, isA<PlayerReady>());
    expect((state as PlayerReady).controller, mpvController);
    expect(state.isFallbackEngine, isTrue);
    verify(() => avController.dispose()).called(1);
  });

  test('surfaces the original AV error when the mpv fallback also fails', () async {
    when(() => playChannelUseCase(channel)).thenReturn(
      TaskEither.right(
        const PlaybackEngineChoice(PlaybackEngineKind.av, m3u8Source, fallback: tsFallback),
      ),
    );
    when(() => avController.initialize(m3u8Source)).thenReturn(
      TaskEither.left(const PlaybackFailure('av failed')),
    );
    when(() => mpvController.initialize(tsFallback)).thenReturn(
      TaskEither.left(const PlaybackFailure('mpv failed too')),
    );

    await cubit.playChannel(channel);

    final state = cubit.state;
    expect(state, isA<PlayerError>());
    expect((state as PlayerError).message, 'av failed');
  });

  test('surfaces PlayerError directly when there is no fallback source (VOD/series)', () async {
    when(() => playChannelUseCase(channel)).thenReturn(
      TaskEither.right(
        const PlaybackEngineChoice(PlaybackEngineKind.av, m3u8Source),
      ),
    );
    when(() => avController.initialize(m3u8Source)).thenReturn(
      TaskEither.left(const PlaybackFailure('no fallback available')),
    );

    await cubit.playChannel(channel);

    final state = cubit.state;
    expect(state, isA<PlayerError>());
    expect((state as PlayerError).message, 'no fallback available');
    verifyNever(() => mpvController.initialize(any()));
  });
}
