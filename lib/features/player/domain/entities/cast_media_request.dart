/// The container a live channel's stream is being cast in. Unlike the local
/// AV/mpv engine split, both values are directly castable — Chromecast's
/// receiver decodes raw MPEG-TS natively, so there's no "fallback engine
/// with no cast route" equivalent here.
enum CastStreamContainer { hls, mpegTs }

class CastMediaRequest {
  const CastMediaRequest({
    required this.url,
    required this.container,
    required this.title,
  });

  final String url;
  final CastStreamContainer container;
  final String title;
}
