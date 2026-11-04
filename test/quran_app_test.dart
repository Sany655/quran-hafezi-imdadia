import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hafezi_imdadia/models/surah.dart';
import 'package:quran_hafezi_imdadia/models/juz.dart';
import 'package:quran_hafezi_imdadia/models/ayah.dart';
import 'package:quran_hafezi_imdadia/models/word_wbw.dart';
import 'package:quran_hafezi_imdadia/models/bookmark.dart';
import 'package:quran_hafezi_imdadia/models/planner_model.dart';
import 'package:quran_hafezi_imdadia/utils/tri_calendar_helper.dart';

void main() {
  group('Quran Data Models Verification Tests', () {
    test('Bookmark model mapping should parse correctly', () {
      final map = {
        'id': 1,
        'page_number': 45,
        'surah_name': 'আল-বাকারাহ',
        'juz_number': 3,
        'created_at': '2026-11-01T12:00:00Z',
      };
      final bm = Bookmark.fromMap(map);
      expect(bm.id, 1);
      expect(bm.pageNumber, 45);
      expect(bm.surahName, 'আল-বাকারাহ');
      expect(bm.juzNumber, 3);
    });
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


    test('TriCalendarHelper numeral and date calculations should be accurate', () {
      expect(TriCalendarHelper.toBnNum(12345), '১২৩৪৫');
      final date = DateTime(2026, 11, 4);
      final bn = TriCalendarHelper.getBengaliDate(date);
      expect(bn.year, 1433);
      expect(bn.monthName, 'কার্তিক');

      final hj = TriCalendarHelper.getHijriDate(date);
      expect(hj.year, 1448);
      expect(hj.monthName, 'জমাদিউল আউয়াল');

      final formatted = TriCalendarHelper.formatTriDateFull(date);
      expect(formatted, contains('নভেম্বর'));
      expect(formatted, contains('কার্তিক'));
      expect(formatted, contains('জমাদিউল আউয়াল'));
    });

    test('PlannerModel and DayLog JSON serialization works correctly', () {
      final model = PlannerModel(profileMode: 'general', hijriOffset: 0);
      final dKey = '2026-11-04';
      model.logs[dKey] = DayLog(
        generalTilawat: 'পারা ১',
        status: 'completed',
        notes: [
          PlannerNote(id: 101, page: 45, text: 'তিলাওয়াত নোট', dateKey: dKey),
        ],
      );

      final map = model.toMap();
      final restored = PlannerModel.fromMap(map);

      expect(restored.profileMode, 'general');
      expect(restored.logs[dKey]?.generalTilawat, 'পারা ১');
      expect(restored.logs[dKey]?.status, 'completed');
      expect(restored.logs[dKey]?.notes.length, 1);
      expect(restored.logs[dKey]?.notes.first.text, 'তিলাওয়াত নোট');
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
      ayah.surahNameBn = 'আল-ফাতিহা';
      expect(ayah.surahNameBn, 'আল-ফাতিহা');
      expect(ayah.words.length, 2);
      expect(ayah.words.first.meaningBn, 'নামে');
      expect(ayah.translationTaisirul, contains('আল্লাহর নামে'));
    });
  });
}
