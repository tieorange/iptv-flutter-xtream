import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../live_tv/domain/entities/live_channel.dart';
import '../../domain/entities/cast_device.dart';
import '../../domain/entities/cast_session_state.dart';
import '../../domain/services/cast_controller.dart';
import '../../domain/usecases/cast_channel_usecase.dart';

/// Chromecast session state for the player screen. Kept as a sibling to
/// [PlayerCubit] rather than folded into it — casting is orthogonal to which
/// local engine (AV/mpv) is active, so it shouldn't couple to that state
/// machine. [PlayerPage] listens to both and pauses/resumes local playback
/// when a cast session starts/ends.
class CastCubit extends Cubit<CastSessionState> {
  CastCubit(this._castController, this._castChannelUseCase) : super(const CastDisconnected()) {
    _sessionSubscription = _castController.sessionState.listen(_onSessionChanged);
  }

  final CastController _castController;
  final CastChannelUseCase _castChannelUseCase;
  late final StreamSubscription<CastSessionState> _sessionSubscription;
  LiveChannel? _pendingChannel;

  Stream<List<CastDevice>> get devices => _castController.availableDevices;

  Future<void> startDiscovery() => _castController.startDiscovery();

  Future<void> stopDiscovery() => _castController.stopDiscovery();

  Future<void> castChannel(LiveChannel channel, CastDevice device) async {
    _pendingChannel = channel;
    await _castController.connect(device);
  }

  Future<void> stopCasting() async {
    _pendingChannel = null;
    await _castController.disconnect();
  }

  Future<void> _onSessionChanged(CastSessionState sessionState) async {
    emit(sessionState);
    final channel = _pendingChannel;
    if (sessionState is CastConnected && channel != null) {
      final result = await _castChannelUseCase(channel).run();
      await result.fold(
        (failure) async => emit(CastSessionError(failure.message)),
        (request) => _castController.loadMedia(request),
      );
    }
  }

  @override
  Future<void> close() async {
    await _sessionSubscription.cancel();
    _castController.dispose();
    return super.close();
  }
}
