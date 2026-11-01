class Surah {
  final int id;
  final String nameAr;
  final String nameEn;
  final String nameBn;
  final String? meaningBn;
  final String revelationType;
  final int totalAyahs;
  final int startPage;

  Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameBn,
    this.meaningBn,
    required this.revelationType,
    required this.totalAyahs,
    required this.startPage,
  });

  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      nameBn: map['name_bn'] as String,
      meaningBn: map['meaning_bn'] as String?,
      revelationType: map['revelation_type'] as String,
      totalAyahs: map['total_ayahs'] as int,
      startPage: map['start_page'] as int,
    );
  }
}
