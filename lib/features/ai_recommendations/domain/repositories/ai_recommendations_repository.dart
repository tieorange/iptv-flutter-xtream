import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_recommendation.dart';
import '../entities/now_playing_snapshot.dart';

abstract interface class AiRecommendationsRepository {
  /// Sends the gathered now-playing snapshots to the AI ranking backend and
  /// returns up to 40 ranked picks.
  TaskEither<Failure, List<AiRecommendation>> rankTopPicks(List<NowPlayingSnapshot> snapshots);
}
