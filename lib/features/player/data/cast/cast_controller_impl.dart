import 'dart:async';

import 'package:flutter_chrome_cast/discovery.dart';
import 'package:flutter_chrome_cast/entities.dart';
import 'package:flutter_chrome_cast/media.dart';
import 'package:flutter_chrome_cast/session.dart';

import '../../domain/entities/cast_device.dart';
import '../../domain/entities/cast_media_request.dart';
import '../../domain/entities/cast_session_state.dart';
import '../../domain/services/cast_controller.dart';
import 'cast_media_info_mapper.dart';

/// Wraps the Google Cast SDK (via `flutter_chrome_cast`) behind
/// [CastController] so the rest of the app never touches the plugin's
/// singletons directly. One instance per app session — cast state is
/// inherently process-wide, unlike the per-playback [PlaybackController]s.
class CastControllerImpl implements CastController {
  CastControllerImpl()
      : _discoveryManager = GoogleCastDiscoveryManager.instance,
        _sessionManager = GoogleCastSessionManager.instance {
    _sessionSubscription = _sessionManager.currentSessionStream.listen(_onSessionChanged);
  }

  final GoogleCastDiscoveryManager _discoveryManager;
  final GoogleCastSessionManager _sessionManager;
  late final StreamSubscription<GoogleCastSession?> _sessionSubscription;

  final _sessionStateController = StreamController<CastSessionState>.broadcast();

  @override
  Stream<CastSessionState> get sessionState => _sessionStateController.stream;

  @override
  Stream<List<CastDevice>> get availableDevices => _discoveryManager.devicesStream.map(
        (devices) => devices
            .map((device) => CastDevice(id: device.deviceID, friendlyName: device.friendlyName))
            .toList(),
      );

  void _onSessionChanged(GoogleCastSession? session) {
    final device = session?.device;
    if (device == null) {
      _sessionStateController.add(const CastDisconnected());
      return;
    }
    _sessionStateController.add(
      CastConnected(CastDevice(id: device.deviceID, friendlyName: device.friendlyName)),
    );
  }

  @override
  Future<void> startDiscovery() => _discoveryManager.startDiscovery();

  @override
  Future<void> stopDiscovery() => _discoveryManager.stopDiscovery();

  @override
  Future<void> connect(CastDevice device) async {
    _sessionStateController.add(CastConnecting(device));
    try {
      final devices = await _discoveryManager.devicesStream.first;
      final target = devices.firstWhere((d) => d.deviceID == device.id);
      await _sessionManager.startSessionWithDevice(target);
    } catch (error) {
      _sessionStateController.add(CastSessionError(error.toString()));
    }
  }

  @override
  Future<void> disconnect() => _sessionManager.endSessionAndStopCasting();

  @override
  Future<void> loadMedia(CastMediaRequest request) {
    return GoogleCastRemoteMediaClient.instance.loadMedia(buildCastMediaInformation(request));
  }

  @override
  Future<void> play() => GoogleCastRemoteMediaClient.instance.play();

  @override
  Future<void> pause() => GoogleCastRemoteMediaClient.instance.pause();

  @override
  void dispose() {
    _sessionSubscription.cancel();
    _sessionStateController.close();
  }
}
