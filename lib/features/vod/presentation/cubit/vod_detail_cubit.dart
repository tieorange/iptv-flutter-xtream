import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vod_detail.dart';
import '../../domain/entities/vod_item.dart';
import '../../domain/usecases/get_vod_detail_usecase.dart';

sealed class VodDetailState {
  const VodDetailState();
}

final class VodDetailLoading extends VodDetailState {
  const VodDetailLoading();
}

final class VodDetailLoaded extends VodDetailState {
  const VodDetailLoaded(this.detail);

  final VodDetail detail;
}

final class VodDetailError extends VodDetailState {
  const VodDetailError(this.message);

  final String message;
}

class VodDetailCubit extends Cubit<VodDetailState> {
  VodDetailCubit(this._getVodDetail) : super(const VodDetailLoading());

  final GetVodDetailUseCase _getVodDetail;

  Future<void> load(VodItem item) async {
    emit(const VodDetailLoading());
    final result = await _getVodDetail(item).run();
    result.fold(
      (failure) => emit(VodDetailError(failure.message)),
      (detail) => emit(VodDetailLoaded(detail)),
    );
  }
}
