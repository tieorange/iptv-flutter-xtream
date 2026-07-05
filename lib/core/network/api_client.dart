import 'package:dio/dio.dart';

import 'retry_interceptor.dart';
import 'scrubbing_log_interceptor.dart';

/// Shared HTTP client for anything the Xtream client wrapper doesn't cover
/// directly (HLS-availability probes). Not used for the Xtream API calls
/// themselves — those go through `XtreamClient`'s own `http.Client`.
Dio buildApiClient() {
  final dio = Dio();
  dio.interceptors.add(ScrubbingLogInterceptor());
  dio.interceptors.add(buildRetryInterceptor(dio));
  return dio;
}
