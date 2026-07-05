import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vod_item.dart';
import '../../domain/usecases/get_vod_items_usecase.dart';

sealed class VodItemsState {
  const VodItemsState();
}

final class VodItemsLoading extends VodItemsState {
  const VodItemsLoading();
}

final class VodItemsLoaded extends VodItemsState {
  const VodItemsLoaded(this.items);

  final List<VodItem> items;
}

final class VodItemsError extends VodItemsState {
  const VodItemsError(this.message);

  final String message;
}

class VodItemsCubit extends Cubit<VodItemsState> {
  VodItemsCubit(this._getVodItems) : super(const VodItemsLoading());

  final GetVodItemsUseCase _getVodItems;

  Future<void> load(int categoryId) async {
    emit(const VodItemsLoading());
    final result = await _getVodItems(categoryId).run();
    result.fold(
      (failure) => emit(VodItemsError(failure.message)),
      (items) => emit(VodItemsLoaded(items)),
    );
  }
}
