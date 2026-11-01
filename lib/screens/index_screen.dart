import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/surah.dart';
import '../models/juz.dart';
import '../database/quran_db_helper.dart';

class IndexScreen extends StatefulWidget {
  final Function(int pageNumber) onPageSelected;

  const IndexScreen({super.key, required this.onPageSelected});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  late Future<List<Surah>> _surahsFuture;
  late Future<List<Juz>> _juzFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _surahsFuture = QuranDbHelper.instance.getAllSurahs();
    _juzFuture = QuranDbHelper.instance.getAllJuz();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'সূচীপত্র',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0F5132),
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFFD4AF37), // Islamic Gold
            indicatorWeight: 3,
            labelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'সূরা সমূহ (১১৪)'),
              Tab(text: 'পারা / জুয (৩০)'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(12),
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
                  // Surahs Tab
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
                            onTap: () {
                              Navigator.pop(context);
                              widget.onPageSelected(surah.startPage);
                            },
                          );
                        },
                      );
                    },
                  ),
                  // Juz Tab
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
                            onTap: () {
                              Navigator.pop(context);
                              widget.onPageSelected(juz.startPage);
                            },
                          );
                        },
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
