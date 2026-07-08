import 'channel_language.dart';

class AiRecommendation {
  const AiRecommendation({
    required this.rank,
    required this.channelId,
    required this.channelName,
    required this.language,
    required this.programTitle,
    required this.reason,
  });

  final int rank;
  final int channelId;
  final String channelName;
  final ChannelLanguage language;
  final String programTitle;
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiRecommendation &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          channelId == other.channelId &&
          channelName == other.channelName &&
          language == other.language &&
          programTitle == other.programTitle &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(rank, channelId, channelName, language, programTitle, reason);
}
