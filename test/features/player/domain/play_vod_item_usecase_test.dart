import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/player/domain/entities/playback_engine_choice.dart';
import 'package:iptv/features/player/domain/usecases/play_vod_item_usecase.dart';
import 'package:iptv/features/vod/domain/entities/vod_detail.dart';
import 'package:iptv/features/vod/domain/repositories/vod_repository.dart';

class _MockVodRepository extends Mock implements VodRepository {}

void main() {
  late _MockVodRepository repository;
  late PlayVodItemUseCase useCase;

  setUp(() {
    repository = _MockVodRepository();
    useCase = PlayVodItemUseCase(repository);
  });

  test('picks the AV engine for mp4 (AVPlayer-friendly)', () async {
    const detail = VodDetail(streamId: 1, name: 'Movie', containerExtension: 'mp4');
    when(() => repository.getStreamUrl(detail))
        .thenReturn(TaskEither.right('http://x/1.mp4'));

    final result = await useCase(detail).run();

    expect(result.getOrElse((_) => throw Exception()).kind, PlaybackEngineKind.av);
  });

  test('falls back to the mpv engine for mkv (not AVPlayer-friendly)', () async {
    const detail = VodDetail(streamId: 2, name: 'Movie', containerExtension: 'mkv');
    when(() => repository.getStreamUrl(detail))
        .thenReturn(TaskEither.right('http://x/2.mkv'));

    final result = await useCase(detail).run();

    expect(result.getOrElse((_) => throw Exception()).kind, PlaybackEngineKind.mpv);
  });

  test('Left(Failure) is preserved when the repository fails', () async {
    const detail = VodDetail(streamId: 3, name: 'Movie', containerExtension: 'mp4');
    when(() => repository.getStreamUrl(detail))
        .thenReturn(TaskEither.left(const NetworkFailure('down')));

    final result = await useCase(detail).run();

    expect(result.isLeft(), isTrue);
  });
}
