import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../live_tv/domain/entities/live_channel.dart';
import '../../data/engines/av_player_controller.dart';
import '../../data/engines/mpv_player_controller.dart';
import '../../domain/entities/playback_engine_choice.dart';
import '../../domain/repositories/playback_controller.dart';
import '../../domain/usecases/play_channel_usecase.dart';

sealed class PlayerState {
  const PlayerState();
}

final class PlayerLoading extends PlayerState {
  const PlayerLoading();
}

final class PlayerReady extends PlayerState {
  const PlayerReady(this.controller, this.isFallbackEngine);

  final PlaybackController controller;

  /// True when playing on the mpv fallback engine — drives hiding the
  /// AirPlay button and showing the fallback badge in `player_page.dart`.
  final bool isFallbackEngine;
}

final class PlayerError extends PlayerState {
  const PlayerError(this.message);

  final String message;
}

class PlayerCubit extends Cubit<PlayerState> {
  PlayerCubit(this._playChannelUseCase) : super(const PlayerLoading());

  final PlayChannelUseCase _playChannelUseCase;

  Future<void> playChannel(LiveChannel channel) async {
    emit(const PlayerLoading());
    final result = await _playChannelUseCase(channel).run();
    await result.fold(
      (failure) async => emit(PlayerError(failure.message)),
      (choice) async {
        final controller = switch (choice.kind) {
          PlaybackEngineKind.av => AvPlayerController(),
          PlaybackEngineKind.mpv => MpvPlayerController(),
        };
        final initResult = await controller.initialize(choice.source).run();
        initResult.fold(
          (failure) => emit(PlayerError(failure.message)),
          (_) => emit(PlayerReady(controller, choice.kind == PlaybackEngineKind.mpv)),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    final state = this.state;
    if (state is PlayerReady) {
      await state.controller.dispose();
    }
    await super.close();
  }
}
