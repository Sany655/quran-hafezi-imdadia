import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/surah.dart';
import '../models/juz.dart';
import '../models/ayah.dart';
import '../models/word_wbw.dart';

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

    // Check if the database exists in the app storage
    final exists = await databaseExists(path);

    if (!exists) {
      // Create parent directory if needed
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load('data/quran_imdadia.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(
      path,
      readOnly: true,
    );
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

    // Attach translations
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

    // Attach word-by-word
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
}
