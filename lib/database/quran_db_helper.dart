import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/surah.dart';
import '../models/juz.dart';
import '../models/ayah.dart';
import '../models/word_wbw.dart';
import '../models/bookmark.dart';

class QuranDbHelper {
  static final QuranDbHelper instance = QuranDbHelper._init();
  static Database? _database;

  QuranDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quran_imdadia.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final exists = await databaseExists(path);
    bool needsCopy = !exists;

    if (exists) {
      try {
        final checkDb = await openDatabase(path, readOnly: true);
        final pageCols = await checkDb.rawQuery("PRAGMA table_info(pages)");
        final hasStartSurah = pageCols.any((c) => c['name'] == 'start_surah_id');
        final tafsirCountRes = await checkDb.rawQuery("SELECT COUNT(*) as cnt FROM tafsirs WHERE tafsir_id = 164");
        final ikCount = Sqflite.firstIntValue(tafsirCountRes) ?? 0;
        await checkDb.close();
        if (!hasStartSurah || ikCount < 6000) {
          needsCopy = true;
        }
      } catch (_) {
        needsCopy = true;
      }
    }

    if (needsCopy) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load('data/quran_imdadia.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(path, readOnly: false);

    // Create Bookmarks & Last Read tables if they don't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page_number INTEGER NOT NULL UNIQUE,
        surah_name TEXT NOT NULL,
        juz_number INTEGER NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS last_read (
        id INTEGER PRIMARY KEY,
        page_number INTEGER NOT NULL,
        surah_name TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    return db;
  }

  // 1. Fetch all Surahs
  Future<List<Surah>> getAllSurahs() async {
    final db = await database;
    final maps = await db.query('surahs', orderBy: 'id ASC');
    return maps.map((e) => Surah.fromMap(e)).toList();
  }

  // 2. Fetch all Juz
  Future<List<Juz>> getAllJuz() async {
    final db = await database;
    final maps = await db.query('juz', orderBy: 'id ASC');
    return maps.map((e) => Juz.fromMap(e)).toList();
  }

  // 3. Fetch Surah by ID
  Future<Surah?> getSurah(int surahId) async {
    final db = await database;
    final maps = await db.query('surahs', where: 'id = ?', whereArgs: [surahId]);
    if (maps.isNotEmpty) {
      return Surah.fromMap(maps.first);
    }
    return null;
  }

  // 3b. Fetch all Page Mappings
  Future<Map<int, Map<String, dynamic>>> getAllPagesInfo() async {
    final db = await database;
    final maps = await db.query('pages');
    Map<int, Map<String, dynamic>> result = {};
    for (var m in maps) {
      final p = m['page_number'] as int;
      result[p] = m;
    }
    return result;
  }

  Future<Map<String, dynamic>?> getPageInfo(int pageNumber) async {
    final db = await database;
    final maps = await db.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // 4. Fetch Ayahs for a Surah with Translations & Word-by-Word
  Future<List<Ayah>> getAyahsForSurah(int surahId) async {
    final db = await database;
    final ayahMaps = await db.query(
      'ayahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
    );

    List<Ayah> ayahs = ayahMaps.map((e) => Ayah.fromMap(e)).toList();

    final transMaps = await db.query(
      'translations',
      where: 'surah_id = ?',
      whereArgs: [surahId],
    );

    for (var a in ayahs) {
      for (var t in transMaps) {
        if (t['ayah_number'] == a.ayahNumber) {
          if (t['edition'] == 'taisirul') {
            a.translationTaisirul = t['text_bn'] as String?;
          } else if (t['edition'] == 'zakaria') {
            a.translationZakaria = t['text_bn'] as String?;
          }
        }
      }
    }

    final wordMaps = await db.query(
      'words_wbw',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'position ASC',
    );

    Map<int, List<WordWbw>> wordsByAyah = {};
    for (var w in wordMaps) {
      final an = w['ayah_number'] as int;
      wordsByAyah.putIfAbsent(an, () => []).add(WordWbw.fromMap(w));
    }

    for (var a in ayahs) {
      a.words = wordsByAyah[a.ayahNumber] ?? [];
    }

    return ayahs;
  }

  // 5. Fetch Tafsir for a specific Ayah
  Future<Map<String, String>> getTafsirForAyah(int surahId, int ayahNumber) async {
    final db = await database;
    final maps = await db.query(
      'tafsirs',
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
    );

    Map<String, String> results = {};
    for (var m in maps) {
      results[m['tafsir_name'] as String] = m['text_bn'] as String;
    }
    return results;
  }

  // 6. Smart Multi-Lingual Search (Banglish, Banglarabi, English-Arabic, Bengali Synonyms)
  static final Map<String, List<String>> _searchSynonyms = {
    // Banglish & English to Bengali
    'salat': ['সালাত', 'নামায', 'নামাজ'],
    'salah': ['সালাত', 'নামায', 'নামাজ'],
    'namaz': ['নামায', 'নামাজ', 'সালাত'],
    'namaj': ['নামায', 'নামাজ', 'সালাত'],
    'roza': ['রোজা', 'রোযা', 'সাওম', 'সিয়াম'],
    'roja': ['রোজা', 'রোযা', 'সাওম', 'সিয়াম'],
    'sawm': ['সাওম', 'সিয়াম', 'রোজা', 'রোযা'],
    'siyam': ['সিয়াম', 'সাওম', 'রোজা', 'রোযা'],
    'ramadan': ['রমযান', 'রমজান', 'সাওম', 'সিয়াম'],
    'ramzan': ['রমযান', 'রমজান', 'সাওম', 'সিয়াম'],
    'zakat': ['যাকাত', 'জাকাত'],
    'jakat': ['যাকাত', 'জাকাত'],
    'jannat': ['জান্নাত', 'জান্নাতুল', 'উদ্যান', 'বেহেশত'],
    'jannah': ['জান্নাত', 'জান্নাতুল'],
    'behesht': ['জান্নাত', 'বেহেশত'],
    'heaven': ['জান্নাত'],
    'paradise': ['জান্নাত'],
    'jahannam': ['জাহান্নাম', 'জাহান্নামের', 'আগুন', 'দোযখ'],
    'jahanam': ['জাহান্নাম', 'জাহান্নামের'],
    'dojokh': ['জাহান্নাম', 'দোযখ'],
    'hell': ['জাহান্নাম'],
    'sabr': ['ধৈর্য', 'সবর'],
    'sobor': ['ধৈর্য', 'সবর'],
    'shirk': ['শিরক', 'শিরক্'],
    'tawhid': ['তাওহীদ', 'তৌহিদ'],
    'touhid': ['তাওহীদ', 'তৌহিদ'],
    'iman': ['ঈমান', 'বিশ্বাস'],
    'eeman': ['ঈমান', 'বিশ্বাস'],
    'momin': ['মুমিন', 'ঈমানদার'],
    'munafik': ['মুনাফিক', 'কপট'],
    'munafiq': ['মুনাফিক', 'কপট'],
    'kafir': ['কাফির', 'অবিশ্বাসী'],
    'riba': ['সুদ', 'রিবা'],
    'shud': ['সুদ', 'রিবা'],
    'sud': ['সুদ', 'রিবা'],
    'qurbani': ['কুরবানী', 'কোরবানী'],
    'korbani': ['কুরবানী', 'কোরবানী'],
    'hajj': ['হজ্জ', 'হজ'],
    'haj': ['হজ্জ', 'হজ'],
    'umrah': ['উমরাহ', 'উমরা'],
    'omra': ['উমরাহ', 'উমরা'],
    'dua': ['দুআ', 'দোয়া', 'প্রার্থনা'],
    'doya': ['দুআ', 'দোয়া', 'প্রার্থনা'],
    'zikr': ['যিকির', 'স্মরণ'],
    'dhikr': ['যিকির', 'স্মরণ'],
    'tawbah': ['তওবা', 'তাওবাহ', 'ক্ষমা'],
    'touba': ['তওবা', 'তাওবাহ', 'ক্ষমা'],
    'wudu': ['ওজু', 'উযূ', 'অযু'],
    'wudhu': ['ওজু', 'উযূ', 'অযু'],
    'oju': ['ওজু', 'উযূ', 'অযু'],
    'quran': ['কুরআন', 'কোরআন', 'কিতাব'],
    'koran': ['কুরআন', 'কোরআন', 'কিতাব'],
    'bismillah': ['বিসমিল্লাহ', 'আল্লাহর নামে'],
    'alhamdulillah': ['আলহামদুলিল্লাহ', 'সকল প্রশংসা'],
    'subhanallah': ['সুবহানাল্লাহ', 'পবিত্র'],
    'astagfirullah': ['ক্ষমা'],
    'allah': ['আল্লাহ', 'আল্লাহর'],
    'rasul': ['রাসূল', 'রাসুল', 'নবী'],
    'prophet': ['নবী', 'রাসূল'],
    'nabi': ['নবী', 'রাসূল'],
    'feresta': ['ফেরেশতা', 'মালাইকা'],
    'angel': ['ফেরেশতা', 'মালাইকা'],
    'kursi': ['কুরসী', 'কুরসির'],
    'ayatul kursi': ['কুরসী', 'কুরসির'],
    'jihad': ['জিহাদ', 'সংগ্রাম'],
    'qiyamah': ['কিয়ামত', 'কিয়ামাহ', 'হাশর'],
    'hasor': ['হাশর', 'কিয়ামত'],

    // Bengali to Synonyms (Banglarobi variants)
    'নামাজ': ['নামায', 'সালাত'],
    'নামায': ['নামাজ', 'সালাত'],
    'সালাত': ['সালাত', 'নামায', 'নামাজ'],
    'রোজা': ['রোজা', 'রোযা', 'সাওম', 'সিয়াম'],
    'রোযা': ['রোজা', 'রোযা', 'সাওম', 'সিয়াম'],
    'সাওম': ['সাওম', 'সিয়াম', 'রোজা', 'রোযা'],
    'সিয়াম': ['সিয়াম', 'সাওম', 'রোজা', 'রোযা'],
    'জাকাত': ['যাকাত', 'জাকাত'],
    'যাকাত': ['যাকাত', 'জাকাত'],
    'সুদ': ['সুদ', 'রিবা'],
    'দোয়া': ['দোয়া', 'দুআ', 'প্রার্থনা'],
    'দুআ': ['দুআ', 'দোয়া', 'প্রার্থনা'],
    'সবর': ['সবর', 'ধৈর্য'],
    'ধৈর্য': ['ধৈর্য', 'সবর'],
    'বেহেশত': ['জান্নাত', 'বেহেশত'],
    'দোযখ': ['জাহান্নাম', 'দোযখ'],
    'ওজু': ['ওজু', 'উযূ', 'অযু'],
    'অযু': ['ওজু', 'উযূ', 'অযু'],
    'তওবা': ['তওবা', 'তাওবাহ', 'ক্ষমা'],
    'কোরবানী': ['কুরবানী', 'কোরবানী'],
    'কুরবানী': ['কুরবানী', 'কোরবানী'],
  };

  Future<List<Map<String, dynamic>>> searchBengali(String query) async {
    final db = await database;
    final clean = query.trim();
    if (clean.isEmpty) return [];

    // Query expansion
    final lower = clean.toLowerCase();
    List<String> terms = [clean];
    if (_searchSynonyms.containsKey(lower)) {
      terms.addAll(_searchSynonyms[lower]!);
    } else if (_searchSynonyms.containsKey(clean)) {
      terms.addAll(_searchSynonyms[clean]!);
    }

    final uniqueTerms = terms.toSet().toList();
    final clauses = uniqueTerms.map((_) => 't.text_bn LIKE ?').join(' OR ');
    final params = uniqueTerms.map((t) => '%$t%').toList();

    final results = await db.rawQuery('''
      SELECT s.id as surah_id, s.name_bn, s.name_en, t.ayah_number, t.edition, t.text_bn
      FROM translations t
      JOIN surahs s ON s.id = t.surah_id
      WHERE ($clauses)
      ORDER BY s.id ASC, t.ayah_number ASC
      LIMIT 100;
    ''', params);
    return results;
  }

  // 7. Bookmarks Management
  Future<bool> isBookmarked(int pageNumber) async {
    final db = await database;
    final maps = await db.query(
      'bookmarks',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
    );
    return maps.isNotEmpty;
  }

  Future<void> addBookmark(int pageNumber, String surahName, int juzNumber) async {
    final db = await database;
    await db.insert(
      'bookmarks',
      {
        'page_number': pageNumber,
        'surah_name': surahName,
        'juz_number': juzNumber,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBookmark(int pageNumber) async {
    final db = await database;
    await db.delete(
      'bookmarks',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
    );
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await database;
    final maps = await db.query('bookmarks', orderBy: 'page_number ASC');
    return maps.map((e) => Bookmark.fromMap(e)).toList();
  }

  // 8. Last Read Management
  Future<void> saveLastRead(int pageNumber, String surahName) async {
    final db = await database;
    await db.insert(
      'last_read',
      {
        'id': 1,
        'page_number': pageNumber,
        'surah_name': surahName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLastRead() async {
    final db = await database;
    final maps = await db.query('last_read', where: 'id = 1');
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}
