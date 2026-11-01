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

    if (!exists) {
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

  // 6. Full-Text Search in Bengali
  Future<List<Map<String, dynamic>>> searchBengali(String query) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT s.id as surah_id, s.name_bn, s.name_en, f.ayah_number, f.edition, f.text_bn
      FROM search_translations_fts f
      JOIN surahs s ON s.id = f.surah_id
      WHERE search_translations_fts MATCH ?
      LIMIT 100;
    ''', [query]);
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
