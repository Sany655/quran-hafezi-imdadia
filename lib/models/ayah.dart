import 'word_wbw.dart';

class Ayah {
  final int id;
  final int surahId;
  final int ayahNumber;
  final String verseKey;
  final String textIndopak;
  final String textUthmani;
  String? translationTaisirul;
  String? translationZakaria;
  String? tafsirAhsanulBayan;
  String? tafsirIbnKathir;
  List<WordWbw> words;

  Ayah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.verseKey,
    required this.textIndopak,
    required this.textUthmani,
    this.translationTaisirul,
    this.translationZakaria,
    this.tafsirAhsanulBayan,
    this.tafsirIbnKathir,
    this.words = const [],
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      id: map['id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      verseKey: map['verse_key'] as String,
      textIndopak: map['text_indopak'] as String,
      textUthmani: map['text_uthmani'] as String,
    );
  }
}
