class LegacyUserDataValidator {
  static List<Map<String, Object?>> validBookmarks(
    Iterable<Map<String, Object?>> rows,
  ) {
    final validRows = <Map<String, Object?>>[];
    for (final row in rows) {
      final pageNumber = row['page_number'];
      final surahName = row['surah_name'];
      final juzNumber = row['juz_number'];
      final createdAt = row['created_at'];
      if (pageNumber is! int ||
          pageNumber < 1 ||
          pageNumber > 612 ||
          surahName is! String ||
          surahName.trim().isEmpty ||
          juzNumber is! int ||
          juzNumber < 1 ||
          juzNumber > 30 ||
          createdAt is! String ||
          createdAt.isEmpty) {
        continue;
      }
      validRows.add({
        'page_number': pageNumber,
        'surah_name': surahName,
        'juz_number': juzNumber,
        'created_at': createdAt,
      });
    }
    return validRows;
  }

  static Map<String, Object?>? validLastRead(
    Iterable<Map<String, Object?>> rows,
  ) {
    if (rows.isEmpty) return null;

    final row = rows.first;
    final pageNumber = row['page_number'];
    final surahName = row['surah_name'];
    final updatedAt = row['updated_at'];
    if (pageNumber is! int ||
        pageNumber < 1 ||
        pageNumber > 612 ||
        surahName is! String ||
        surahName.trim().isEmpty ||
        updatedAt is! String ||
        updatedAt.isEmpty) {
      return null;
    }

    return {
      'id': 1,
      'page_number': pageNumber,
      'surah_name': surahName,
      'updated_at': updatedAt,
    };
  }
}
