import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/epg_program.dart';
import '../../domain/usecases/get_now_next_usecase.dart';

sealed class NowNextState {
  const NowNextState();
}

final class NowNextLoading extends NowNextState {
  const NowNextLoading();
}

final class NowNextLoaded extends NowNextState {
  const NowNextLoaded(this.programs);

  final List<EpgProgram> programs;
}

final class NowNextError extends NowNextState {
  const NowNextError(this.message);

  final String message;
}

class NowNextCubit extends Cubit<NowNextState> {
  NowNextCubit(this._getNowNext) : super(const NowNextLoading());

  final GetNowNextUseCase _getNowNext;

  Future<void> load(int channelId) async {
    final result = await _getNowNext(channelId).run();
    result.fold(
      (failure) => emit(NowNextError(failure.message)),
      (programs) => emit(NowNextLoaded(programs)),
    );
  }
}
