import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static Future<Database>? _initDbFuture;

  static const int kDatabaseVersion = 2;

  // In-memory static caches for instant zero-lag page navigation
  static List<Surah>? _cachedSurahs;
  static List<Juz>? _cachedJuz;
  static Map<int, Map<String, dynamic>>? _cachedPagesInfo;

  QuranDbHelper._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _initDbFuture ??= _initDB('quran_imdadia.db');
    _database = await _initDbFuture!;
    return _database!;
  }

  Future<void> _copyAssetDb(String path) async {
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}
    ByteData data = await rootBundle.load('data/quran_imdadia.db');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final exists = await databaseExists(path);
    if (!exists) {
      debugPrint('Database file does not exist, copying from assets...');
      await _copyAssetDb(path);
    }

    var db = await openDatabase(path, readOnly: false);

    // Fast version check: PRAGMA user_version takes 0.1ms
    try {
      final vRes = await db.rawQuery("PRAGMA user_version");
      final currentVersion = Sqflite.firstIntValue(vRes) ?? 0;

      if (currentVersion < kDatabaseVersion) {
        debugPrint('Old database version ($currentVersion < $kDatabaseVersion), upgrading...');
        await db.close();
        await deleteDatabase(path);
        await _copyAssetDb(path);
        db = await openDatabase(path, readOnly: false);
        await db.execute('PRAGMA user_version = $kDatabaseVersion;');
      }
    } catch (e) {
      debugPrint('Error during version verification: $e');
    }

    // Fast table creation with IF NOT EXISTS
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS planner_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        data TEXT NOT NULL
      );
    ''');

    return db;
  }

  Future<String?> getPlannerStateJson() async {
    final db = await database;
    final rows = await db.query(
      'planner_state',
      columns: ['data'],
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['data'] as String?;
  }

  Future<void> savePlannerStateJson(String json) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.insert(
        'planner_state',
        {'id': 1, 'data': json},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // 1. Fetch all Surahs (with in-memory cache)
  Future<List<Surah>> getAllSurahs() async {
    if (_cachedSurahs != null && _cachedSurahs!.isNotEmpty) {
      return _cachedSurahs!;
    }
    final db = await database;
    final maps = await db.query('surahs', orderBy: 'id ASC');
    _cachedSurahs = maps.map((e) => Surah.fromMap(e)).toList();
    return _cachedSurahs!;
  }

  // 2. Fetch all Juz (with in-memory cache)
  Future<List<Juz>> getAllJuz() async {
    if (_cachedJuz != null && _cachedJuz!.isNotEmpty) {
      return _cachedJuz!;
    }
    final db = await database;
    final maps = await db.query('juz', orderBy: 'id ASC');
    _cachedJuz = maps.map((e) => Juz.fromMap(e)).toList();
    return _cachedJuz!;
  }

  // 3. Fetch Surah by ID
  Future<Surah?> getSurah(int surahId) async {
    final surahs = await getAllSurahs();
    final matches = surahs.where((s) => s.id == surahId);
    if (matches.isNotEmpty) return matches.first;
    return null;
  }

  // 3b. Fetch all Page Mappings (with in-memory cache)
  Future<Map<int, Map<String, dynamic>>> getAllPagesInfo() async {
    if (_cachedPagesInfo != null && _cachedPagesInfo!.isNotEmpty) {
      return _cachedPagesInfo!;
    }
    final db = await database;
    final maps = await db.query('pages');
    Map<int, Map<String, dynamic>> result = {};
    for (var m in maps) {
      final p = m['page_number'] as int;
      result[p] = m;
    }
    _cachedPagesInfo = result;
    return _cachedPagesInfo!;
  }

  Future<Map<String, dynamic>?> getPageInfo(int pageNumber) async {
    final allPages = await getAllPagesInfo();
    return allPages[pageNumber];
  }

  Future<int?> getPageForAyah(int surahId, int ayahNumber) async {
    final db = await database;
    final rows = await db.query(
      'ayahs',
      columns: ['page_number'],
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final page = rows.first['page_number'];
    return page is int ? page : int.tryParse(page?.toString() ?? '');
  }

  // 4. Fetch Ayahs for a Page with Translations & Word-by-Word
  Future<List<Ayah>> getAyahsForPage(int pageNumber) async {
    try {
      final db = await database;

      // 1. Fetch verse keys for this page from pages table
      final pageMaps = await db.query(
        'pages',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        limit: 1,
      );

      List<String> vks = [];
      if (pageMaps.isNotEmpty) {
        final verseKeysStr = pageMaps.first['verse_keys'] as String?;
        if (verseKeysStr != null && verseKeysStr.trim().isNotEmpty) {
          vks = verseKeysStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }

      List<Map<String, dynamic>> ayahMaps = [];

      if (vks.isNotEmpty) {
        final placeholders = List.filled(vks.length, '?').join(',');
        ayahMaps = await db.rawQuery('''
          SELECT a.*, s.name_bn as surah_name_bn
          FROM ayahs a
          LEFT JOIN surahs s ON s.id = a.surah_id
          WHERE a.verse_key IN ($placeholders)
        ''', vks);
      } else {
        // Fallback 1: Query by ayahs.page_number
        ayahMaps = await db.rawQuery('''
          SELECT a.*, s.name_bn as surah_name_bn
          FROM ayahs a
          LEFT JOIN surahs s ON s.id = a.surah_id
          WHERE a.page_number = ?
          ORDER BY a.id ASC
        ''', [pageNumber]);

        if (ayahMaps.isNotEmpty) {
          vks = ayahMaps.map((m) => m['verse_key'] as String).toList();
        } else if (pageMaps.isNotEmpty) {
          // Fallback 2: Query by start_surah_id/start_ayah_number to end_surah_id/end_ayah_number
          final p = pageMaps.first;
          final sSid = (p['start_surah_id'] ?? 1) as int;
          final sAid = (p['start_ayah_number'] ?? 1) as int;
          final eSid = (p['end_surah_id'] ?? sSid) as int;
          final eAid = (p['end_ayah_number'] ?? sAid) as int;

          if (sSid == eSid) {
            ayahMaps = await db.rawQuery('''
              SELECT a.*, s.name_bn as surah_name_bn
              FROM ayahs a
              LEFT JOIN surahs s ON s.id = a.surah_id
              WHERE a.surah_id = ? AND a.ayah_number >= ? AND a.ayah_number <= ?
              ORDER BY a.ayah_number ASC
            ''', [sSid, sAid, eAid]);
          } else {
            ayahMaps = await db.rawQuery('''
              SELECT a.*, s.name_bn as surah_name_bn
              FROM ayahs a
              LEFT JOIN surahs s ON s.id = a.surah_id
              WHERE (a.surah_id = ? AND a.ayah_number >= ?)
                 OR (a.surah_id = ? AND a.ayah_number <= ?)
                 OR (a.surah_id > ? AND a.surah_id < ?)
              ORDER BY a.id ASC
            ''', [sSid, sAid, eSid, eAid, sSid, eSid]);
          }
          vks = ayahMaps.map((m) => m['verse_key'] as String).toList();
        }
      }

      if (ayahMaps.isEmpty) return [];

      final Map<String, Ayah> ayahsByVk = {};
      for (var m in ayahMaps) {
        final a = Ayah.fromMap(m);
        a.surahNameBn = m['surah_name_bn'] as String?;
        ayahsByVk[a.verseKey] = a;
      }

      final List<Ayah> ayahs = [];
      for (var vk in vks) {
        if (ayahsByVk.containsKey(vk)) {
          ayahs.add(ayahsByVk[vk]!);
        }
      }
      for (var a in ayahsByVk.values) {
        if (!ayahs.contains(a)) {
          ayahs.add(a);
        }
      }

      if (ayahs.isEmpty) return [];

      // Query translations
      final conditions = List.filled(ayahs.length, '(surah_id = ? AND ayah_number = ?)').join(' OR ');
      final List<dynamic> params = [];
      for (var a in ayahs) {
        params.add(a.surahId);
        params.add(a.ayahNumber);
      }

      final transMaps = await db.rawQuery(
        'SELECT surah_id, ayah_number, edition, text_bn FROM translations WHERE $conditions',
        params,
      );

      for (var t in transMaps) {
        final sid = (t['surah_id'] as int?) ?? 0;
        final an = (t['ayah_number'] as int?) ?? 0;
        final vk = '$sid:$an';
        final a = ayahsByVk[vk];
        if (a != null) {
          if (t['edition'] == 'taisirul') {
            a.translationTaisirul = t['text_bn'] as String?;
          } else if (t['edition'] == 'zakaria') {
            a.translationZakaria = t['text_bn'] as String?;
          }
        }
      }

      // Query Word-by-Word data (including id)
      final wordMaps = await db.rawQuery(
        'SELECT id, surah_id, ayah_number, position, text_arabic, meaning_bn FROM words_wbw WHERE $conditions ORDER BY surah_id, ayah_number, position ASC',
        params,
      );

      final Map<String, List<WordWbw>> wordsByVk = {};
      for (var w in wordMaps) {
        final sid = (w['surah_id'] as int?) ?? 0;
        final an = (w['ayah_number'] as int?) ?? 0;
        final vk = '$sid:$an';
        wordsByVk.putIfAbsent(vk, () => []).add(WordWbw.fromMap(w));
      }

      for (var a in ayahs) {
        a.words = wordsByVk[a.verseKey] ?? [];
      }

      return ayahs;
    } catch (e, stack) {
      debugPrint('Error in getAyahsForPage($pageNumber): $e\n$stack');
      return [];
    }
  }

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
