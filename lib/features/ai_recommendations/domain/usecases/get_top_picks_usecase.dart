import 'package:fpdart/fpdart.dart';

import '../../../../core/config/env.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_talker.dart';
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
      appTalker.info('GetTopPicksUseCase: starting');
      if (!Env.hasOpenAiApiKey) {
        throw const AiFailure(
          'OpenAI API key is not configured for this build. See dart_define.example.json.',
        );
      }

      final categoriesEither = await _liveTvRepository.getCategories().run();
      final categories = categoriesEither.getOrElse((failure) => throw failure);
      final languagesByCategory = _matchCategories(categories);
      if (languagesByCategory.isEmpty) {
        throw const AiFailure(
          'No English, Russian, Polish, or Ukrainian categories found on this provider.',
        );
      }
      appTalker.info(
        'GetTopPicksUseCase: matched ${languagesByCategory.length} language categories',
      );

      final allChannelsEither = await _liveTvRepository.getAllChannels().run();
      final allChannels = allChannelsEither.getOrElse((failure) => throw failure);
      final sampled = _sampleByLanguage(allChannels, languagesByCategory);
      appTalker.info('GetTopPicksUseCase: sampled ${sampled.length} channels');

      final snapshots = await _gatherNowPlaying(sampled);
      if (snapshots.isEmpty) {
        throw const AiFailure(
          'No now-playing data available from your provider right now.',
        );
      }
      appTalker.info(
        'GetTopPicksUseCase: gathered ${snapshots.length} now-playing snapshots, '
        'calling OpenAI',
      );

      final ranked = await _aiRepository.rankTopPicks(snapshots).run();
      final picks = ranked.getOrElse((failure) => throw failure);
      appTalker.info('GetTopPicksUseCase: OpenAI returned ${picks.length} picks');
      return _sortByLanguage(picks);
    }, (error, stackTrace) {
      final failure = _toFailure(error, stackTrace);
      appTalker.error('GetTopPicksUseCase: failed — ${failure.message}', error, stackTrace);
      return failure;
    });
  }

  static const _languageOrder = [
    ChannelLanguage.russian,
    ChannelLanguage.ukrainian,
    ChannelLanguage.polish,
    ChannelLanguage.english,
  ];

  /// Groups picks by language in [_languageOrder], keeping the AI's relative
  /// ranking within each group, then renumbers 1..N for display.
  List<AiRecommendation> _sortByLanguage(List<AiRecommendation> picks) {
    final sorted = [...picks]..sort((a, b) {
        final languageCompare =
            _languageOrder.indexOf(a.language).compareTo(_languageOrder.indexOf(b.language));
        if (languageCompare != 0) return languageCompare;
        return a.rank.compareTo(b.rank);
      });
    return [
      for (var i = 0; i < sorted.length; i++) sorted[i].copyWith(rank: i + 1),
    ];
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
      final either = await _epgRepository.getNowNext(entry.channel.id).run().timeout(_epgTimeout);
      final programs = either.getOrElse((failure) => throw failure);
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
