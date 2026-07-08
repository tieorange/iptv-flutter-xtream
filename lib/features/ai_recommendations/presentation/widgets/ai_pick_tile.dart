import 'package:flutter/material.dart';

import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/channel_language.dart';

class AiPickTile extends StatelessWidget {
  const AiPickTile({super.key, required this.pick, this.onTap});

  final AiRecommendation pick;
  final VoidCallback? onTap;

  bool get _isTopThree => pick.rank <= 3;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 0,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _RankBadge(rank: pick.rank, highlighted: _isTopThree),
              const SizedBox(width: 12.0),
              _ChannelIcon(iconUrl: pick.channelIcon),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pick.channelName,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      pick.programTitle,
                      style: textTheme.bodyMedium?.copyWith(color: colors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      pick.reason,
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(Icons.play_circle_fill, color: colors.primary, size: 30.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelIcon extends StatelessWidget {
  const _ChannelIcon({required this.iconUrl});

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: 44.0,
        height: 44.0,
        color: colors.surfaceContainerHighest,
        alignment: Alignment.center,
        child: iconUrl == null || iconUrl!.isEmpty
            ? Icon(Icons.live_tv, color: colors.onSurfaceVariant, size: 22.0)
            : Image.network(
                iconUrl!,
                width: 44.0,
                height: 44.0,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.live_tv, color: colors.onSurfaceVariant, size: 22.0),
              ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.highlighted});

  final int rank;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 36.0,
      height: 36.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? colors.primary : colors.secondaryContainer,
      ),
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: highlighted ? colors.onPrimary : colors.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class LanguageChip extends StatelessWidget {
  const LanguageChip({super.key, required this.language});

  final ChannelLanguage language;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        language.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
