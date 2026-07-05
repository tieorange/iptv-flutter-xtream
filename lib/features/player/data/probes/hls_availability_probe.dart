import 'package:dio/dio.dart';

/// Probes whether a panel's `.m3u8` endpoint actually works before handing
/// it to AVPlayer — some panels only emit raw `.ts` despite the URL
/// resolving. A HEAD request with a short timeout is enough: we only care
/// about reachability/status, not the body.
class HlsAvailabilityProbe {
  HlsAvailabilityProbe(this._dio);

  final Dio _dio;

  Future<bool> isAvailable(String url) async {
    try {
      final response = await _dio.head<void>(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode;
      return status != null && status < 400;
    } catch (_) {
      return false;
    }
  }
}
