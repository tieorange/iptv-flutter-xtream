import 'package:fpdart/fpdart.dart';

import '../../../../core/config/env.dart';
import '../../../../core/error/failures.dart';
import '../../../epg/domain/repositories/epg_repository.dart';
import '../../../live_tv/domain/entities/live_category.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import '../../../live_tv/domain/repositories/live_tv_repository.dart';
import '../entities/ai_recommendation.dart';
import '../entities/channel_language.dart';
import '../entities/now_playing_snapshot.dart';
import '../repositories/ai_recommendations_repository.dart';

/// Orchestrates: match language categories -> sample channels -> fetch
/// now-playing EPG with bounded concurrency -> rank via
/// [AiRecommendationsRepository]. This is the one deliberate exception to
/// "usecase = thin delegate to one repository" — the same accepted shape as
/// `SearchAllUseCase`, which also composes across multiple features'
/// repositories because the composition can't live behind any single
/// feature's repository interface.
class GetTopPicksUseCase {
  GetTopPicksUseCase(this._liveTvRepository, this._epgRepository, this._aiRepository);

  final LiveTvRepository _liveTvRepository;
  final EpgRepository _epgRepository;
  final AiRecommendationsRepository _aiRepository;

  static const _maxPerLanguage = 120;
  static const _epgConcurrency = 8;
  static const _epgTimeout = Duration(seconds: 6);

  TaskEither<Failure, List<AiRecommendation>> call() {
    return TaskEither.tryCatch(() async {
      if (!Env.hasOpenAiApiKey) {
        throw const AiFailure(
          'OpenAI API key is not configured for this build. See dart_define.example.json.',
        );
      }

      final categories = await _liveTvRepository.getCategories().getOrElse(
            (failure) => throw failure,
          )();
      final languagesByCategory = _matchCategories(categories);
      if (languagesByCategory.isEmpty) {
        throw const AiFailure(
          'No English, Russian, Polish, or Ukrainian categories found on this provider.',
        );
      }

      final allChannels = await _liveTvRepository.getAllChannels().getOrElse(
            (failure) => throw failure,
          )();
      final sampled = _sampleByLanguage(allChannels, languagesByCategory);

      final snapshots = await _gatherNowPlaying(sampled);
      if (snapshots.isEmpty) {
        throw const AiFailure(
          'No now-playing data available from your provider right now.',
        );
      }

      return _aiRepository.rankTopPicks(snapshots).getOrElse((failure) => throw failure)();
    }, _toFailure);
  }

  Map<int, Set<ChannelLanguage>> _matchCategories(List<LiveCategory> categories) {
    final map = <int, Set<ChannelLanguage>>{};
    for (final category in categories) {
      final languages = matchCategoryLanguages(category.name);
      if (languages.isNotEmpty) map[category.id] = languages;
    }
    return map;
  }

  List<_LanguageChannel> _sampleByLanguage(
    List<LiveChannel> allChannels,
    Map<int, Set<ChannelLanguage>> languagesByCategory,
  ) {
    final countPerLanguage = <ChannelLanguage, int>{};
    final seenChannelIds = <int>{};
    final sampled = <_LanguageChannel>[];

    for (final channel in allChannels) {
      final languages = languagesByCategory[channel.categoryId];
      if (languages == null || !seenChannelIds.add(channel.id)) continue;

      for (final language in languages) {
        final count = countPerLanguage[language] ?? 0;
        if (count >= _maxPerLanguage) continue;
        countPerLanguage[language] = count + 1;
        sampled.add(_LanguageChannel(channel, language));
      }
    }
    return sampled;
  }

  Future<List<NowPlayingSnapshot>> _gatherNowPlaying(List<_LanguageChannel> sampled) async {
    final snapshots = <NowPlayingSnapshot>[];
    for (var i = 0; i < sampled.length; i += _epgConcurrency) {
      final batch = sampled.skip(i).take(_epgConcurrency);
      final results = await Future.wait(batch.map(_fetchOne));
      snapshots.addAll(results.whereType<NowPlayingSnapshot>());
    }
    return snapshots;
  }

  Future<NowPlayingSnapshot?> _fetchOne(_LanguageChannel entry) async {
    try {
      final programs = await _epgRepository
          .getNowNext(entry.channel.id)
          .getOrElse((failure) => throw failure)()
          .timeout(_epgTimeout);
      if (programs.isEmpty) return null;
      return NowPlayingSnapshot(
        channel: entry.channel,
        language: entry.language,
        program: programs.first,
      );
    } catch (_) {
      return null;
    }
  }

  Failure _toFailure(Object error, StackTrace _) {
    if (error is Failure) return error;
    return AiFailure(error.toString());
  }
}

class _LanguageChannel {
  const _LanguageChannel(this.channel, this.language);

  final LiveChannel channel;
  final ChannelLanguage language;
}
