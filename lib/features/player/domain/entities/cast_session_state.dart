import 'cast_device.dart';

sealed class CastSessionState {
  const CastSessionState();
}

final class CastDisconnected extends CastSessionState {
  const CastDisconnected();
}

final class CastConnecting extends CastSessionState {
  const CastConnecting(this.device);

  final CastDevice device;
}

final class CastConnected extends CastSessionState {
  const CastConnected(this.device);

  final CastDevice device;
}

final class CastSessionError extends CastSessionState {
  const CastSessionError(this.message);

  final String message;
}
