import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/features/player/data/engines/playback_engine_selector_impl.dart';
import 'package:iptv/features/player/data/probes/hls_availability_probe.dart';
import 'package:iptv/features/player/domain/entities/playback_engine_choice.dart';

class _MockProbe extends Mock implements HlsAvailabilityProbe {}

void main() {
  late _MockProbe probe;
  late PlaybackEngineSelectorImpl selector;

  const m3u8Url = 'http://panel/live/u/p/1.m3u8';
  const tsUrl = 'http://panel/live/u/p/1.ts';

  setUp(() {
    probe = _MockProbe();
    selector = PlaybackEngineSelectorImpl(probe);
  });

  test('chooses the AV engine with the m3u8 source when the probe succeeds', () async {
    when(() => probe.isAvailable(m3u8Url)).thenAnswer((_) async => true);

    final choice = await selector.choose(m3u8Url: m3u8Url, tsUrl: tsUrl);

    expect(choice.kind, PlaybackEngineKind.av);
    expect(choice.source.url, m3u8Url);
    expect(choice.source.containerExtension, 'm3u8');
    expect(choice.fallback?.url, tsUrl);
    expect(choice.fallback?.containerExtension, 'ts');
  });

  test('falls back to the mpv engine with the ts source when the probe fails (404/timeout)', () async {
    when(() => probe.isAvailable(m3u8Url)).thenAnswer((_) async => false);

    final choice = await selector.choose(m3u8Url: m3u8Url, tsUrl: tsUrl);

    expect(choice.kind, PlaybackEngineKind.mpv);
    expect(choice.source.url, tsUrl);
    expect(choice.source.containerExtension, 'ts');
    expect(choice.fallback, isNull);
  });

  test('never probes the ts URL — only m3u8 availability decides the engine', () async {
    when(() => probe.isAvailable(m3u8Url)).thenAnswer((_) async => true);

    await selector.choose(m3u8Url: m3u8Url, tsUrl: tsUrl);

    verifyNever(() => probe.isAvailable(tsUrl));
  });
}
