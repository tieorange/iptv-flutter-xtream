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
  final userIndex = segments.indexWhere(
    (segment) => segment == uri.queryParameters['username'],
  );
  final scrubbedSegments = [
    for (var i = 0; i < segments.length; i++)
      if (i == userIndex || i == userIndex + 1) '***' else segments[i],
  ];

  return uri
      .replace(
        pathSegments: scrubbedSegments,
        queryParameters: scrubbedQuery.isEmpty ? null : scrubbedQuery,
      )
      .toString();
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
