import 'package:dio/dio.dart';
import 'package:talker/talker.dart';

import '../config/env.dart';
import 'retry_interceptor.dart';
import 'scrubbing_log_interceptor.dart';

/// Shared HTTP client for anything the Xtream client wrapper doesn't cover
/// directly (HLS-availability probes). Not used for the Xtream API calls
/// themselves — those go through `XtreamClient`'s own `http.Client`.
Dio buildApiClient(Talker talker) {
  final dio = Dio();
  dio.interceptors.add(ScrubbingLogInterceptor(talker));
  dio.interceptors.add(buildRetryInterceptor(dio));
  return dio;
}

/// Dedicated client for OpenAI's Chat Completions API (the "Top 40 Now" AI
/// picks feature) — separate from [buildApiClient] because it carries a
/// bearer token and needs longer timeouts than the HLS-probe traffic that
/// client is tuned for. `ScrubbingLogInterceptor` only logs the scrubbed URL
/// and status, never headers/body, so the bearer token is safe with the
/// same interceptor.
Dio buildOpenAiApiClient(Talker talker) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.openai.com/v1',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
    headers: {
      'Authorization': 'Bearer ${Env.openAiApiKey}',
      'Content-Type': 'application/json',
    },
  ));
  dio.interceptors.add(ScrubbingLogInterceptor(talker));
  dio.interceptors.add(buildRetryInterceptor(dio));
  return dio;
}
