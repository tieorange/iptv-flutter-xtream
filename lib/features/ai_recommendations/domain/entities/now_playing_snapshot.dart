import '../../../epg/domain/entities/epg_program.dart';
import '../../../live_tv/domain/entities/live_channel.dart';
import 'channel_language.dart';

/// One channel's current program, tagged with the language its category
/// matched to. Cross-feature domain entity — the same accepted pattern as
/// `SearchResult` in the `search` feature, which also composes entities from
/// other features' domains.
class NowPlayingSnapshot {
  const NowPlayingSnapshot({
    required this.channel,
    required this.language,
    required this.program,
  });

  final LiveChannel channel;
  final ChannelLanguage language;
  final EpgProgram program;
}
