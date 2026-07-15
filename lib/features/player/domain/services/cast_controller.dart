import '../entities/cast_device.dart';
import '../entities/cast_media_request.dart';
import '../entities/cast_session_state.dart';

/// Chromecast session control, kept behind an interface so the presentation
/// layer never imports `flutter_chrome_cast` directly — mirrors how
/// [PlaybackController] keeps `video_player`/`media_kit` out of the cubit.
abstract interface class CastController {
  Stream<CastSessionState> get sessionState;

  Stream<List<CastDevice>> get availableDevices;

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Future<void> connect(CastDevice device);

  Future<void> disconnect();

  Future<void> loadMedia(CastMediaRequest request);

  Future<void> play();

  Future<void> pause();

  void dispose();
}
