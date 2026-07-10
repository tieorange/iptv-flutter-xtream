// NOTE: asserts against `flutter_chrome_cast`'s `entities.dart` API surface
// (contentType/streamType/hlsSegmentFormat field and enum names) — verify
// this still compiles against the installed plugin version after
// `flutter pub get`, since it couldn't be checked in the environment this
// was written in.
import 'package:flutter_chrome_cast/entities.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptv/features/player/data/cast/cast_media_info_mapper.dart';
import 'package:iptv/features/player/domain/entities/cast_media_request.dart';

void main() {
  test('maps a .ts request to raw MPEG-TS content type', () {
    const request = CastMediaRequest(
      url: 'http://panel/live/u/p/1.ts',
      container: CastStreamContainer.mpegTs,
      title: 'Test Channel',
    );

    final info = buildCastMediaInformation(request);

    expect(info.contentType, 'video/mp2t');
    expect(info.contentUrl.toString(), request.url);
    expect(info.streamType, CastMediaStreamType.LIVE);
  });

  test('maps a .m3u8 request to HLS content type with the TS segment hint', () {
    const request = CastMediaRequest(
      url: 'http://panel/live/u/p/1.m3u8',
      container: CastStreamContainer.hls,
      title: 'Test Channel',
    );

    final info = buildCastMediaInformation(request);

    expect(info.contentType, 'application/x-mpegURL');
    expect(info.hlsSegmentFormat, HLSSegmentFormat.ts);
  });
}
