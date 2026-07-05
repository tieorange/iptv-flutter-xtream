class VodDetail {
  const VodDetail({
    required this.streamId,
    required this.name,
    this.description,
    this.coverUrl,
    this.genre,
    this.durationSecs,
    this.containerExtension,
  });

  final int streamId;
  final String name;
  final String? description;
  final String? coverUrl;
  final String? genre;
  final int? durationSecs;
  final String? containerExtension;
}
