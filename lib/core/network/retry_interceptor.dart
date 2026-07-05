import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

/// `dio_smart_retry`'s defaults already do the right thing here: transient
/// failures (timeouts, connection errors, 5xx, 408/429) get retried with
/// backoff; 4xx (wrong credentials, not found, ...) never does — retrying a
/// bad-password request would just make a login screen look hung instead
/// of failing fast.
RetryInterceptor buildRetryInterceptor(Dio dio) {
  return RetryInterceptor(dio: dio);
}
