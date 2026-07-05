import 'package:flutter/material.dart';

import '../../../epg/presentation/widgets/now_next_strip.dart';
import '../../../favorites/domain/entities/favorite_item.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/entities/live_channel.dart';

class ChannelListTile extends StatelessWidget {
  const ChannelListTile({super.key, required this.channel, required this.onTap});

  final LiveChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: channel.streamIcon == null || channel.streamIcon!.isEmpty
          ? const Icon(Icons.live_tv)
          : Image.network(
              channel.streamIcon!,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.live_tv),
            ),
      title: Text(channel.name),
      subtitle: NowNextStrip(channelId: channel.id),
      trailing: FavoriteButton(
        item: FavoriteItem(
          itemId: channel.id,
          itemType: FavoriteItemType.live,
          name: channel.name,
          streamIcon: channel.streamIcon,
        ),
      ),
      onTap: onTap,
    );
  }
}
