import 'package:dio/dio.dart';
import 'package:talker/talker.dart';

import '../utils/url_scrubber.dart';

const _startTimeKey = 'scrubbing_log_interceptor_start_time';

/// Logs every request/response/failure via [Talker], with credentials always
/// stripped from the URL first — Xtream URLs embed username/password as both
/// query params and path segments. Deliberately hand-rolled instead of using
/// `talker_dio_logger` directly: that package prints the raw request path,
/// which would leak Xtream credentials and the OpenAI bearer token.
class ScrubbingLogInterceptor extends Interceptor {
  ScrubbingLogInterceptor(this._talker);

  final Talker _talker;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now();
    _talker.info(
      '→ ${options.method} ${scrubUrl(options.uri.toString())}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final ms = _elapsedMs(response.requestOptions);
    _talker.info(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${scrubUrl(response.requestOptions.uri.toString())}$ms',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ms = _elapsedMs(err.requestOptions);
    final url = scrubUrl(err.requestOptions.uri.toString());
    _talker.error(
      '✗ ${err.requestOptions.method} $url failed: '
      '${err.response?.statusCode ?? err.type}$ms',
    );
    handler.next(err);
  }

  String _elapsedMs(RequestOptions options) {
    final start = options.extra[_startTimeKey];
    if (start is! DateTime) return '';
    return ' (${DateTime.now().difference(start).inMilliseconds}ms)';
  }
}
