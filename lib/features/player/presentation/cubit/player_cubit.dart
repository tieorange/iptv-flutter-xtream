import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../../series/domain/entities/series_episode.dart';
import '../../../vod/domain/entities/vod_detail.dart';
import '../../data/engines/av_player_controller.dart';
import '../../data/engines/mpv_player_controller.dart';
import '../../domain/entities/playback_engine_choice.dart';
import '../../domain/repositories/playback_controller.dart';
import '../../domain/usecases/play_channel_usecase.dart';
import '../../domain/usecases/play_series_episode_usecase.dart';
import '../../domain/usecases/play_vod_item_usecase.dart';

sealed class PlayerState {
  const PlayerState();
}

final class PlayerLoading extends PlayerState {
  const PlayerLoading();
}

final class PlayerReady extends PlayerState {
  const PlayerReady(this.controller, {required this.isFallbackEngine, required this.isLive});

  final PlaybackController controller;

  /// True when playing on the mpv fallback engine — drives hiding the
  /// AirPlay button and showing the fallback badge in `player_page.dart`.
  final bool isFallbackEngine;

  /// VOD/series playback shows a seek bar; live TV doesn't.
  final bool isLive;
}

final class PlayerError extends PlayerState {
  const PlayerError(this.message);

  final String message;
}

class PlayerCubit extends Cubit<PlayerState> {
  PlayerCubit(
    this._playChannelUseCase,
    this._playVodItemUseCase,
    this._playSeriesEpisodeUseCase, {
    PlaybackController Function() avPlayerFactory = AvPlayerController.new,
    PlaybackController Function() mpvPlayerFactory = MpvPlayerController.new,
  })  : _avPlayerFactory = avPlayerFactory,
        _mpvPlayerFactory = mpvPlayerFactory,
        super(const PlayerLoading());

  final PlayChannelUseCase _playChannelUseCase;
  final PlayVodItemUseCase _playVodItemUseCase;
  final PlaySeriesEpisodeUseCase _playSeriesEpisodeUseCase;
  final PlaybackController Function() _avPlayerFactory;
  final PlaybackController Function() _mpvPlayerFactory;

  Future<void> playChannel(LiveChannel channel) =>
      _resolve(_playChannelUseCase(channel), isLive: true);

  Future<void> playVodItem(VodDetail detail) =>
      _resolve(_playVodItemUseCase(detail), isLive: false);

  Future<void> playEpisode(SeriesEpisode episode) =>
      _resolve(_playSeriesEpisodeUseCase(episode), isLive: false);

  Future<void> _resolve(TaskEither<Failure, PlaybackEngineChoice> task, {required bool isLive}) async {
    emit(const PlayerLoading());
    final result = await task.run();
    await result.fold(
      (failure) async => emit(PlayerError(failure.message)),
      (choice) async {
        final controller = switch (choice.kind) {
          PlaybackEngineKind.av => _avPlayerFactory(),
          PlaybackEngineKind.mpv => _mpvPlayerFactory(),
        };
        final initResult = await controller.initialize(choice.source).run();
        await initResult.fold(
          (failure) async {
            final fallback = choice.fallback;
            if (fallback == null) {
              emit(PlayerError(failure.message));
              return;
            }
            await controller.dispose();
            final fallbackController = _mpvPlayerFactory();
            final fallbackResult = await fallbackController.initialize(fallback).run();
            fallbackResult.fold(
              (_) => emit(PlayerError(failure.message)),
              (_) => emit(PlayerReady(
                fallbackController,
                isFallbackEngine: true,
                isLive: isLive,
              )),
            );
          },
          (_) async => emit(PlayerReady(
            controller,
            isFallbackEngine: choice.kind == PlaybackEngineKind.mpv,
            isLive: isLive,
          )),
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
