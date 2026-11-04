class WordWbw {
  final int id;
  final int surahId;
  final int ayahNumber;
  final int position;
  final String textArabic;
  final String meaningBn;

  WordWbw({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.position,
    required this.textArabic,
    required this.meaningBn,
  });

  factory WordWbw.fromMap(Map<String, dynamic> map) {
    return WordWbw(
      id: (map['id'] as int?) ?? 0,
      surahId: (map['surah_id'] as int?) ?? 0,
      ayahNumber: (map['ayah_number'] as int?) ?? 0,
      position: (map['position'] as int?) ?? 0,
      textArabic: (map['text_arabic'] as String?) ?? '',
      meaningBn: (map['meaning_bn'] as String?) ?? '',
    );
  }
}
