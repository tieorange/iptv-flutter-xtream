import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/url_scrubber.dart';
import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/now_playing_snapshot.dart';
import '../../domain/repositories/ai_recommendations_repository.dart';
import '../datasources/openai_remote_datasource.dart';

class AiRecommendationsRepositoryImpl implements AiRecommendationsRepository {
  AiRecommendationsRepositoryImpl(this._remote);

  final OpenAiRemoteDataSource _remote;

  @override
  TaskEither<Failure, List<AiRecommendation>> rankTopPicks(List<NowPlayingSnapshot> snapshots) {
    return TaskEither.tryCatch(() => _remote.rankTopPicks(snapshots), _toFailure);
  }

  Failure _toFailure(Object error, StackTrace _) {
    if (error is Failure) return error;
    return UnknownFailure(scrubMessage(error.toString()));
  }
}
