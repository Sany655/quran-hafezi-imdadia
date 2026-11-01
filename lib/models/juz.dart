class Juz {
  final int id;
  final String nameAr;
  final String nameEn;
  final String nameBn;
  final int startPage;

  Juz({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameBn,
    required this.startPage,
  });

  factory Juz.fromMap(Map<String, dynamic> map) {
    return Juz(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      nameBn: map['name_bn'] as String,
      startPage: map['start_page'] as int,
    );
  }
}
