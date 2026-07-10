import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/features/live_tv/domain/entities/live_channel.dart';
import 'package:iptv/features/live_tv/domain/repositories/live_tv_repository.dart';
import 'package:iptv/features/player/data/probes/hls_availability_probe.dart';
import 'package:iptv/features/player/domain/entities/cast_media_request.dart';
import 'package:iptv/features/player/domain/usecases/cast_channel_usecase.dart';

class _MockLiveTvRepository extends Mock implements LiveTvRepository {}

class _MockProbe extends Mock implements HlsAvailabilityProbe {}

void main() {
  late _MockLiveTvRepository repository;
  late _MockProbe probe;
  late CastChannelUseCase useCase;

  const channel = LiveChannel(id: 1, name: 'Test Channel', categoryId: 1);
  const m3u8Url = 'http://panel/live/u/p/1.m3u8';
  const tsUrl = 'http://panel/live/u/p/1.ts';

  setUp(() {
    repository = _MockLiveTvRepository();
    probe = _MockProbe();
    useCase = CastChannelUseCase(repository, probe);
    when(() => repository.getStreamUrl(channel, format: 'm3u8'))
        .thenReturn(TaskEither.right(m3u8Url));
    when(() => repository.getStreamUrl(channel, format: 'ts')).thenReturn(TaskEither.right(tsUrl));
  });

  test('casts the m3u8 URL as HLS when the probe reports it available', () async {
    when(() => probe.isAvailable(m3u8Url)).thenAnswer((_) async => true);

    final result = await useCase(channel).run();

    final request = result.getOrElse((_) => throw StateError('expected Right'));
    expect(request.url, m3u8Url);
    expect(request.container, CastStreamContainer.hls);
  });

  test('casts the raw ts URL as MPEG-TS when the probe reports the m3u8 unavailable', () async {
    when(() => probe.isAvailable(m3u8Url)).thenAnswer((_) async => false);

    final result = await useCase(channel).run();

    final request = result.getOrElse((_) => throw StateError('expected Right'));
    expect(request.url, tsUrl);
    expect(request.container, CastStreamContainer.mpegTs);
  });
}
