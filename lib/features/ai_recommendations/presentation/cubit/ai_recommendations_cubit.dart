import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ai_recommendation.dart';
import '../../domain/usecases/get_top_picks_usecase.dart';

sealed class AiRecommendationsState {
  const AiRecommendationsState();
}

final class AiRecommendationsLoading extends AiRecommendationsState {
  const AiRecommendationsLoading();
}

final class AiRecommendationsLoaded extends AiRecommendationsState {
  const AiRecommendationsLoaded(this.picks);

  final List<AiRecommendation> picks;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiRecommendationsLoaded && listEquals(picks, other.picks);

  @override
  int get hashCode => Object.hashAll(picks);
}

final class AiRecommendationsError extends AiRecommendationsState {
  const AiRecommendationsError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AiRecommendationsError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}

class AiRecommendationsCubit extends Cubit<AiRecommendationsState> {
  AiRecommendationsCubit(this._getTopPicks) : super(const AiRecommendationsLoading());

  final GetTopPicksUseCase _getTopPicks;

  Future<void> load() async {
    emit(const AiRecommendationsLoading());
    final result = await _getTopPicks().run();
    result.fold(
      (failure) => emit(AiRecommendationsError(failure.message)),
      (picks) => emit(AiRecommendationsLoaded(picks)),
    );
  }
}
