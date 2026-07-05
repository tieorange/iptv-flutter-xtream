import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vod_category.dart';
import '../../domain/usecases/get_vod_categories_usecase.dart';

sealed class VodCategoriesState {
  const VodCategoriesState();
}

final class VodCategoriesLoading extends VodCategoriesState {
  const VodCategoriesLoading();
}

final class VodCategoriesLoaded extends VodCategoriesState {
  const VodCategoriesLoaded(this.categories);

  final List<VodCategory> categories;
}

final class VodCategoriesError extends VodCategoriesState {
  const VodCategoriesError(this.message);

  final String message;
}

class VodCategoriesCubit extends Cubit<VodCategoriesState> {
  VodCategoriesCubit(this._getVodCategories) : super(const VodCategoriesLoading());

  final GetVodCategoriesUseCase _getVodCategories;

  Future<void> load() async {
    emit(const VodCategoriesLoading());
    final result = await _getVodCategories().run();
    result.fold(
      (failure) => emit(VodCategoriesError(failure.message)),
      (categories) => emit(VodCategoriesLoaded(categories)),
    );
  }
}
