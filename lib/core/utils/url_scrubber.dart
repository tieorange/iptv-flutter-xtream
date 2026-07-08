/// Strips Xtream credentials from a URL before it's ever written to a log
/// line or crash report. Xtream URLs embed `username`/`password` both as
/// path segments (`/live/{user}/{pass}/...`) and query parameters
/// (`player_api.php?username=...&password=...`).
String scrubUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return '***';

  final scrubbedQuery = <String, String>{
    for (final entry in uri.queryParameters.entries)
      entry.key: _isSensitiveKey(entry.key) ? '***' : entry.value,
  };

  final segments = uri.pathSegments.toList();
  final queryUsername = uri.queryParameters['username'];
  final userIndex = queryUsername == null
      ? -1
      : segments.indexWhere((segment) => segment == queryUsername);
  // Stream URLs (live/movie/series) embed username/password as the first
  // two path segments with no query params at all, so the query-based
  // lookup above finds nothing — fall back to masking segments 0 and 1,
  // matching how every stream base URI in this app is actually built
  // (see XtreamClient's `$username/$password` path construction).
  final maskUserIndex = userIndex != -1 ? userIndex : (segments.length >= 2 ? 0 : -1);
  final scrubbedSegments = [
    for (var i = 0; i < segments.length; i++)
      if (i == maskUserIndex || i == maskUserIndex + 1) '***' else segments[i],
  ];

  return uri
      .replace(
        pathSegments: scrubbedSegments,
        queryParameters: scrubbedQuery.isEmpty ? null : scrubbedQuery,
      )
      .toString();
}

/// Scrubs any Xtream URL that appears *inside* a larger string — e.g. a
/// `video_player`/`media_kit` exception message that embeds the stream URL
/// (credentials and all) via `error.toString()`. Unlike [scrubUrl], the
/// input doesn't have to be a bare URL.
String scrubMessage(String message) {
  var result = message.replaceAllMapped(
    RegExp(r'(username|password|user|pass)=[^&\s"]*', caseSensitive: false),
    (m) => '${m[1]}=***',
  );
  result = result.replaceAllMapped(
    RegExp(r'/(live|movie|series)/[^/\s"]+/[^/\s"]+/'),
    (m) => '/${m[1]}/***/***/',
  );
  return result;
}

bool _isSensitiveKey(String key) {
  final normalized = key.toLowerCase();
  return normalized == 'username' ||
      normalized == 'user' ||
      normalized == 'password' ||
      normalized == 'pass' ||
      normalized.contains('token') ||
      normalized.contains('secret');
}
