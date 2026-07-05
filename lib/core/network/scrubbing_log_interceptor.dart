import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/url_scrubber.dart';

/// Logs request failures in debug builds only, with credentials always
/// stripped from the URL first — Xtream URLs embed username/password as
/// both query params and path segments.
class ScrubbingLogInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final url = err.requestOptions.uri.toString();
      debugPrint('[network] ${err.requestOptions.method} ${scrubUrl(url)} '
          'failed: ${err.response?.statusCode ?? err.type}');
    }
    handler.next(err);
  }
}
