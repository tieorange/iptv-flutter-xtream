import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/live_channel.dart';
import '../../domain/usecases/get_live_channels_usecase.dart';

sealed class LiveChannelsState {
  const LiveChannelsState();
}

final class LiveChannelsLoading extends LiveChannelsState {
  const LiveChannelsLoading();
}

final class LiveChannelsLoaded extends LiveChannelsState {
  const LiveChannelsLoaded(this.channels);

  final List<LiveChannel> channels;
}

final class LiveChannelsError extends LiveChannelsState {
  const LiveChannelsError(this.message);

  final String message;
}

class LiveChannelsCubit extends Cubit<LiveChannelsState> {
  LiveChannelsCubit(this._getLiveChannels) : super(const LiveChannelsLoading());

  final GetLiveChannelsUseCase _getLiveChannels;

  Future<void> load(int categoryId) async {
    emit(const LiveChannelsLoading());
    final result = await _getLiveChannels(categoryId).run();
    result.fold(
      (failure) => emit(LiveChannelsError(failure.message)),
      (channels) => emit(LiveChannelsLoaded(channels)),
    );
  }
}
