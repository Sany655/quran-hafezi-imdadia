import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hafezi_imdadia/models/surah.dart';
import 'package:quran_hafezi_imdadia/models/juz.dart';
import 'package:quran_hafezi_imdadia/models/ayah.dart';
import 'package:quran_hafezi_imdadia/models/word_wbw.dart';

void main() {
  group('Quran Data Models Verification Tests', () {
    test('Surah model mapping should parse correctly', () {
      final map = {
        'id': 1,
        'name_ar': 'الفاتحة',
        'name_en': 'Al-Fatihah',
        'name_bn': 'আল-ফাতিহা',
        'meaning_bn': 'সূচনা',
        'revelation_type': 'মাক্কী',
        'total_ayahs': 7,
        'start_page': 2,
      };

      final surah = Surah.fromMap(map);
      expect(surah.id, 1);
      expect(surah.nameBn, 'আল-ফাতিহা');
      expect(surah.startPage, 2);
      expect(surah.totalAyahs, 7);
    });

    test('Juz model mapping should parse correctly', () {
      final map = {
        'id': 1,
        'name_ar': 'الم',
        'name_en': 'Alif-Lam-Meem',
        'name_bn': 'আলিফ লাম মীম',
        'start_page': 2,
      };

      final juz = Juz.fromMap(map);
      expect(juz.id, 1);
      expect(juz.nameBn, 'আলিফ লাম মীম');
      expect(juz.startPage, 2);
    });

    test('Ayah and WordWbw relationships should attach properly', () {
      final ayah = Ayah(
        id: 1,
        surahId: 1,
        ayahNumber: 1,
        verseKey: '1:1',
        textIndopak: 'بِسۡمِ اللهِ الرَّحۡمٰنِ الرَّحِيۡمِ',
        textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        translationTaisirul: '(আরম্ভ করছি) পরম করুণাময় অসীম দয়াময় আল্লাহর নামে।',
        words: [
          WordWbw(
            id: 1,
            surahId: 1,
            ayahNumber: 1,
            position: 1,
            textArabic: 'بِسۡمِ',
            meaningBn: 'নামে',
          ),
          WordWbw(
            id: 2,
            surahId: 1,
            ayahNumber: 1,
            position: 2,
            textArabic: 'اللهِ',
            meaningBn: 'আল্লাহ (র)',
          ),
        ],
      );

      expect(ayah.ayahNumber, 1);
      expect(ayah.words.length, 2);
      expect(ayah.words.first.meaningBn, 'নামে');
      expect(ayah.translationTaisirul, contains('আল্লাহর নামে'));
    });
  });
}
