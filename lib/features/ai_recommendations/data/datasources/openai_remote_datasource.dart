import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/channel_language.dart';
import '../../domain/entities/now_playing_snapshot.dart';

class OpenAiRemoteDataSource {
  OpenAiRemoteDataSource(this._dio);

  final Dio _dio;

  static const _model = 'gpt-4o';
  static const _maxSnapshotsInPrompt = 500;
  static const _maxDescriptionChars = 140;

  Future<List<AiRecommendation>> rankTopPicks(List<NowPlayingSnapshot> snapshots) async {
    final trimmed = snapshots.take(_maxSnapshotsInPrompt).toList();
    final byChannelId = {for (final s in trimmed) s.channel.id: s};

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': _model,
          'temperature': 0.7,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': _buildUserPrompt(trimmed)},
          ],
        },
      );

      final content = response.data?['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const AiFailure('OpenAI returned an empty response.');
      }
      return _parsePicks(content, byChannelId);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  String get _systemPrompt =>
      'You are an expert TV programming curator. You will be given a list of live TV '
      'channels currently airing programs, each tagged with its language '
      '(English, Russian, Polish, or Ukrainian). Pick the 40 most fun, interesting, or '
      'binge-worthy things to watch right now across all languages — mix languages '
      'naturally rather than grouping by language. Respond with ONLY a JSON object of '
      'the shape {"picks": [{"rank": 1, "channelId": 123, "channelName": "...", '
      '"language": "english", "programTitle": "...", "reason": "one short sentence"}, '
      '...]} with up to 40 entries ordered by rank ascending. "language" must be one of '
      '"english", "russian", "polish", "ukrainian".';

  String _buildUserPrompt(List<NowPlayingSnapshot> snapshots) {
    final buffer = StringBuffer('Currently airing:\n');
    for (final s in snapshots) {
      final description = _decodeMaybeBase64(s.program.description);
      final shortDescription = description == null
          ? ''
          : ' — ${description.substring(0, description.length.clamp(0, _maxDescriptionChars))}';
      buffer.writeln(
        '- id=${s.channel.id} | ${s.channel.name} (${s.language.label}): '
        '"${_decodeMaybeBase64(s.program.title) ?? s.program.title}"$shortDescription',
      );
    }
    return buffer.toString();
  }

  /// Some Xtream panels base64-encode `get_short_epg` title/description
  /// fields (e.g. `"QkJDIE5ld3MgYXQgVGVu"` -> `"BBC News at Ten"`); others
  /// send plain text. Try decoding — if it doesn't look like valid decodable
  /// UTF-8 text, assume it was already plain.
  String? _decodeMaybeBase64(String? raw) {
    if (raw == null || raw.isEmpty) return raw;
    try {
      final decoded = utf8.decode(base64.decode(raw));
      return decoded;
    } catch (_) {
      return raw;
    }
  }

  List<AiRecommendation> _parsePicks(
    String content,
    Map<int, NowPlayingSnapshot> byChannelId,
  ) {
    late final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } on FormatException {
      throw const AiFailure('OpenAI returned a malformed response.');
    }

    final rawPicks = parsed['picks'];
    if (rawPicks is! List) {
      throw const AiFailure('OpenAI response was missing the "picks" list.');
    }

    final picks = <AiRecommendation>[];
    for (final entry in rawPicks) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        final channelId = (entry['channelId'] as num).toInt();
        final language = ChannelLanguage.values.firstWhere(
          (l) => l.name == (entry['language'] as String).toLowerCase(),
          orElse: () => byChannelId[channelId]?.language ?? ChannelLanguage.english,
        );
        picks.add(AiRecommendation(
          rank: (entry['rank'] as num).toInt(),
          channelId: channelId,
          channelName: entry['channelName'] as String,
          language: language,
          programTitle: entry['programTitle'] as String,
          reason: entry['reason'] as String,
        ));
      } catch (_) {
        continue;
      }
    }
    if (picks.isEmpty) {
      throw const AiFailure('OpenAI response contained no usable picks.');
    }
    return picks.take(40).toList();
  }

  AiFailure _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) {
      return const AiFailure('OpenAI rejected the API key — check your build configuration.');
    }
    if (status == 429) {
      return const AiFailure('OpenAI rate-limited this request. Try again shortly.');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const AiFailure('Timed out waiting for OpenAI.');
    }
    return AiFailure('OpenAI request failed: ${e.message ?? e.type.name}');
  }
}
