import 'channel_language.dart';

class AiRecommendation {
  const AiRecommendation({
    required this.rank,
    required this.channelId,
    required this.channelName,
    required this.channelIcon,
    required this.language,
    required this.programTitle,
    required this.reason,
  });

  final int rank;
  final int channelId;
  final String channelName;
  final String? channelIcon;
  final ChannelLanguage language;
  final String programTitle;
  final String reason;

  AiRecommendation copyWith({int? rank}) => AiRecommendation(
        rank: rank ?? this.rank,
        channelId: channelId,
        channelName: channelName,
        channelIcon: channelIcon,
        language: language,
        programTitle: programTitle,
        reason: reason,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiRecommendation &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          channelId == other.channelId &&
          channelName == other.channelName &&
          channelIcon == other.channelIcon &&
          language == other.language &&
          programTitle == other.programTitle &&
          reason == other.reason;

  @override
  int get hashCode =>
      Object.hash(rank, channelId, channelName, channelIcon, language, programTitle, reason);
}
