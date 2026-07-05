class EpgProgram {
  const EpgProgram({required this.title, this.start, this.end, this.description});

  final String title;
  final DateTime? start;
  final DateTime? end;
  final String? description;
}
