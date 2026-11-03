import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/surah.dart';
import '../models/juz.dart';
import '../models/bookmark.dart';
import '../database/quran_db_helper.dart';
import 'mushaf_view_screen.dart';
import 'search_screen.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  late Future<List<Surah>> _surahsFuture;
  late Future<List<Juz>> _juzFuture;
  List<Bookmark> _bookmarks = [];
  Map<String, dynamic>? _lastRead;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _surahsFuture = QuranDbHelper.instance.getAllSurahs();
    _juzFuture = QuranDbHelper.instance.getAllJuz();
    _loadBookmarksAndLastRead();
  }

  void _loadBookmarksAndLastRead() async {
    final b = await QuranDbHelper.instance.getAllBookmarks();
    final lr = await QuranDbHelper.instance.getLastRead();
    if (mounted) {
      setState(() {
        _bookmarks = b;
        _lastRead = lr;
      });
    }
  }

  void _openPage(int pageNumber) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafViewScreen(initialPage: pageNumber),
      ),
    );
    _loadBookmarksAndLastRead();
  }

  void _deleteBookmark(Bookmark bm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'বুকমার্ক অপসারণ',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'পৃষ্ঠা ${bm.pageNumber} (${bm.surahName}) বুকমার্কটি কি মুছে ফেলতে চান?',
            style: GoogleFonts.notoSansBengali(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('না', style: GoogleFonts.notoSansBengali(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await QuranDbHelper.instance.removeBookmark(bm.pageNumber);
                _loadBookmarksAndLastRead();
              },
              child: Text('হ্যাঁ, মুছুন', style: GoogleFonts.notoSansBengali()),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Color(0xFF0F5132)),
              const SizedBox(width: 8),
              Text(
                'উৎস ও তথ্যের বিবরণ',
                style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '• ১০০% অফলাইন ও কোনো পারমিশন প্রয়োজন নেই।\n'
                  '• ক্যালিগ্রাফি ও পৃষ্ঠা: ঐতিহ্যবাহী ইমদাদিয়া লাইব্রেরী ১৫ লাইন ছাপা (চকবাজার, ঢাকা)।\n'
                  '• আরবি পাঠ্য: তানযীল প্রজেক্ট ও বাদশাহ ফাহদ কুরআন কমপ্লেক্স (মদিনা)।\n'
                  '• বাংলা অনুবাদ ১: ড. আবু বকর মুহাম্মাদ যাকারিয়া (বাদশাহ ফাহদ কমপ্লেক্স অনুমোদিত)।\n'
                  '• বাংলা অনুবাদ ২: তাইসীরুল কুরআন (তাওহীদ পাবলিকেশন্স)।\n'
                  '• শব্দে শব্দে অর্থ: কুরআন ডট কম ওপেন কর্পাস।\n'
                  '• তাফসীর: তাফসীরে আহসানুল বায়ান ও তাফসীর ইবনে কাসীর।\n\n'
                  'সকল তথ্য ওপেন ডাটা ও উন্মুক্ত ধর্মীয় কল্যাণার্থে সংকলিত।\n\n'
                  'কৃতজ্ঞতা ও দো’আ:\n'
                  'এই ডিজিটাল কুরআন প্রজেক্টটি বাস্তবায়নে অনুপ্রেরণা, উন্মুক্ত তথ্য ও ডিজিটাল কুরআন সংরক্ষণে নিয়োজিত পূর্ববর্তী সকল নিষ্ঠাবান আলেম, ক্যালিগ্রাফার এবং মুসলিম ডেভেলপার ভাইদের প্রতি আমরা আন্তরিকভাবে কৃতজ্ঞ। মহান আল্লাহ তাআলা তাঁদের প্রত্যেকের এই দ্বীনি মেহনতকে কবুল করুন এবং এটিকে তাঁদের ও আমাদের জন্য সাদাকায়ে জারিয়া বানিয়ে দিন। আমীন।',
                  style: GoogleFonts.notoSansBengali(fontSize: 13, height: 1.6, color: Colors.black87),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('ঠিক আছে', style: GoogleFonts.notoSansBengali()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Quran - For huffaz',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: const Color(0xFF0F5132),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'উৎস ও তথ্য',
              onPressed: _showAboutDialog,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'অনুসন্ধান',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(
                      onResultSelected: (sid, aid) async {
                        final s = await QuranDbHelper.instance.getSurah(sid);
                        if (s != null) {
                          _openPage(s.startPage);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFFD4AF37), // Islamic Gold
            indicatorWeight: 3,
            labelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'সূরা সমূহ (১১৪)'),
              Tab(text: 'পারা / জুয (৩০)'),
              Tab(text: 'বুকমার্ক'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Resume Last Read Card (if exists)
            if (_lastRead != null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F5132), Color(0xFF198754)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFFD4AF37), size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'সর্বশেষ পড়া পৃষ্ঠা',
                              style: GoogleFonts.notoSansBengali(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'পৃষ্ঠা ${_lastRead!['page_number']} (${_lastRead!['surah_name']})',
                              style: GoogleFonts.notoSansBengali(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _openPage(_lastRead!['page_number'] as int),
                      child: Text(
                        'চালিয়ে যান',
                        style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Search Bar for quick filter
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'সূরা খুঁজুন (যেমন: ফাতিহা, বাকারা)...',
                  hintStyle: GoogleFonts.notoSansBengali(fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0F5132)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Surahs
                  FutureBuilder<List<Surah>>(
                    future: _surahsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final filtered = snapshot.data!.where((s) {
                        return s.nameBn.toLowerCase().contains(_searchQuery) ||
                            s.nameEn.toLowerCase().contains(_searchQuery) ||
                            s.id.toString() == _searchQuery;
                      }).toList();

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final surah = filtered[index];
                          return ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0F5132).withOpacity(0.1),
                              ),
                              child: Text(
                                '${surah.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F5132),
                                ),
                              ),
                            ),
                            title: Text(
                              surah.nameBn,
                              style: GoogleFonts.notoSansBengali(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '${surah.nameEn} • ${surah.totalAyahs} আয়াত • পৃষ্ঠা ${surah.startPage}',
                              style: GoogleFonts.notoSansBengali(fontSize: 12),
                            ),
                            trailing: Text(
                              surah.nameAr,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 18,
                                color: Color(0xFF0F5132),
                              ),
                            ),
                            onTap: () => _openPage(surah.startPage),
                          );
                        },
                      );
                    },
                  ),

                  // Tab 2: Juz / Para
                  FutureBuilder<List<Juz>>(
                    future: _juzFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final juzList = snapshot.data!;
                      return ListView.separated(
                        itemCount: juzList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final juz = juzList[index];
                          return ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD4AF37).withOpacity(0.2),
                              ),
                              child: Text(
                                '${juz.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B6B00),
                                ),
                              ),
                            ),
                            title: Text(
                              'পারা ${juz.id}: ${juz.nameBn}',
                              style: GoogleFonts.notoSansBengali(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              'পৃষ্ঠা ${juz.startPage}',
                              style: GoogleFonts.notoSansBengali(fontSize: 12),
                            ),
                            trailing: Text(
                              juz.nameAr,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 17,
                                color: Color(0xFF0F5132),
                              ),
                            ),
                            onTap: () => _openPage(juz.startPage),
                          );
                        },
                      );
                    },
                  ),

                  // Tab 3: Bookmarks
                  _bookmarks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'কোন বুকমার্ক সংরক্ষিত নেই',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'যেকোনো পৃষ্ঠায় কিছুক্ষণ চেপে ধরলে (Long Press)\nবুকমার্ক করতে পারবেন',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _bookmarks.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final bm = _bookmarks[index];
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.bookmark, color: Color(0xFFD4AF37)),
                              ),
                              title: Text(
                                'পৃষ্ঠা ${bm.pageNumber}: ${bm.surahName}',
                                style: GoogleFonts.notoSansBengali(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                'পারা ${bm.juzNumber}',
                                style: GoogleFonts.notoSansBengali(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'বুকমার্ক মুছুন',
                                onPressed: () => _deleteBookmark(bm),
                              ),
                              onTap: () => _openPage(bm.pageNumber),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
