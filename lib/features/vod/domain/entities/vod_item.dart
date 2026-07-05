class VodItem {
  const VodItem({
    required this.id,
    required this.name,
    required this.categoryId,
    this.streamIcon,
    this.containerExtension,
  });

  final int id;
  final String name;
  final int categoryId;
  final String? streamIcon;
  final String? containerExtension;
}
