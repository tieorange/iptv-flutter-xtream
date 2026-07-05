enum FavoriteItemType { live, vod, series }

class FavoriteItem {
  const FavoriteItem({
    required this.itemId,
    required this.itemType,
    required this.name,
    this.streamIcon,
  });

  final int itemId;
  final FavoriteItemType itemType;
  final String name;
  final String? streamIcon;

  @override
  bool operator ==(Object other) =>
      other is FavoriteItem && other.itemId == itemId && other.itemType == itemType;

  @override
  int get hashCode => Object.hash(itemId, itemType);
}
