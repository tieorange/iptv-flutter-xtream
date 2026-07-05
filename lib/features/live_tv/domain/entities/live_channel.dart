class LiveChannel {
  const LiveChannel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.streamIcon,
    this.epgChannelId,
  });

  final int id;
  final String name;
  final int categoryId;
  final String? streamIcon;
  final String? epgChannelId;
}
