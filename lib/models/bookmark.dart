class Bookmark {
  final int id;
  final int pageNumber;
  final String surahName;
  final int juzNumber;
  final String createdAt;

  Bookmark({
    required this.id,
    required this.pageNumber,
    required this.surahName,
    required this.juzNumber,
    required this.createdAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int,
      pageNumber: map['page_number'] as int,
      surahName: map['surah_name'] as String,
      juzNumber: map['juz_number'] as int,
      createdAt: map['created_at'] as String,
    );
  }
}
