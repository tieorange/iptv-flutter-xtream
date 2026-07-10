import 'package:flutter_chrome_cast/entities.dart';

import '../../domain/entities/cast_media_request.dart';

/// Maps our engine-agnostic [CastMediaRequest] to the Cast SDK's media
/// descriptor. `.ts` requests are sent as raw MPEG-TS (`video/mp2t`) since
/// Chromecast's receiver decodes that container directly — this is what
/// lets casting succeed for the same raw streams that only the AirPlay-less
/// mpv fallback engine could play locally. `.m3u8` requests set the HLS
/// segment format hint since Xtream's HLS segments are themselves MPEG-TS.
GoogleCastMediaInformationIOS buildCastMediaInformation(CastMediaRequest request) {
  final contentUrl = Uri.parse(request.url);
  final metadata = GoogleCastMovieMediaMetadata(title: request.title);
  return switch (request.container) {
    CastStreamContainer.mpegTs => GoogleCastMediaInformationIOS(
        contentId: request.url,
        contentUrl: contentUrl,
        contentType: 'video/mp2t',
        streamType: CastMediaStreamType.LIVE,
        metadata: metadata,
      ),
    CastStreamContainer.hls => GoogleCastMediaInformationIOS(
        contentId: request.url,
        contentUrl: contentUrl,
        contentType: 'application/x-mpegURL',
        streamType: CastMediaStreamType.LIVE,
        hlsSegmentFormat: HLSSegmentFormat.ts,
        metadata: metadata,
      ),
  };
}
