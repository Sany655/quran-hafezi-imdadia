import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/ayah.dart';
import '../models/surah.dart';
import '../database/quran_db_helper.dart';

class StudySheet extends StatefulWidget {
  final Surah surah;
  final int initialAyahNumber;

  const StudySheet({
    super.key,
    required this.surah,
    this.initialAyahNumber = 1,
  });

  @override
  State<StudySheet> createState() => _StudySheetState();
}

class _StudySheetState extends State<StudySheet> {
  late Future<List<Ayah>> _ayahsFuture;
  bool _showWordByWord = true;
  String _selectedTranslation = 'taisirul'; // 'taisirul' or 'zakaria'

  @override
  void initState() {
    super.initState();
    _ayahsFuture = QuranDbHelper.instance.getAyahsForSurah(widget.surah.id);
  }

  void _showTafsirModal(BuildContext context, Ayah ayah) async {
    final tafsirs = await QuranDbHelper.instance.getTafsirForAyah(
      widget.surah.id,
      ayah.ayahNumber,
    );

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            expand: false,
            builder: (_, scrollController) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'তাফসীর: ${widget.surah.nameBn} (${ayah.ayahNumber})',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5132),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const TabBar(
                    labelColor: Color(0xFF0F5132),
                    indicatorColor: Color(0xFF0F5132),
                    tabs: [
                      Tab(text: 'আহসানুল বায়ান'),
                      Tab(text: 'ইবনে কাসীর'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Ahsanul Bayaan
                        SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Html(
                            data: tafsirs['ahsanul_bayan'] ?? 'এই আয়াতের জন্য তাফসীর উপলব্ধ নয়।',
                            style: {
                              "body": Style(
                                fontSize: FontSize(16),
                                lineHeight: const LineHeight(1.6),
                                fontFamily: GoogleFonts.notoSansBengali().fontFamily,
                              ),
                            },
                          ),
                        ),
                        // Ibn Kathir
                        SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Html(
                            data: tafsirs['ibn_kathir'] ?? 'এই আয়াতের জন্য ইবনে কাসীর তাফসীর উপলব্ধ নয়।',
                            style: {
                              "body": Style(
                                fontSize: FontSize(16),
                                lineHeight: const LineHeight(1.6),
                                fontFamily: GoogleFonts.notoSansBengali().fontFamily,
                              ),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.surah.nameBn,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F5132),
                      ),
                    ),
                    Text(
                      '${widget.surah.nameEn} • ${widget.surah.totalAyahs} আয়াত • ${widget.surah.revelationType}',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showWordByWord ? Icons.view_column : Icons.view_headline,
                        color: const Color(0xFF0F5132),
                      ),
                      tooltip: _showWordByWord ? 'শব্দে শব্দে বন্ধ করুন' : 'শব্দে শব্দে দেখুন',
                      onPressed: () {
                        setState(() {
                          _showWordByWord = !_showWordByWord;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Ayahs List
          Expanded(
            child: FutureBuilder<List<Ayah>>(
              future: _ayahsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('কোন তথ্য পাওয়া যায়নি'));
                }

                final ayahs = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ayahs.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final ayah = ayahs[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ayah number badge & actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F5132).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'আয়াত ${ayah.ayahNumber}',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F5132),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.menu_book, size: 16, color: Color(0xFF0F5132)),
                              label: Text(
                                'তাফসীর',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F5132),
                                ),
                              ),
                              onPressed: () => _showTafsirModal(context, ayah),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Arabic text
                        Text(
                          ayah.textIndopak,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            height: 1.8,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Word-by-Word View
                        if (_showWordByWord && ayah.words.isNotEmpty) ...[
                          Wrap(
                            alignment: WrapAlignment.end,
                            textDirection: TextDirection.rtl,
                            spacing: 8,
                            runSpacing: 8,
                            children: ayah.words.map((w) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      w.textArabic,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      w.meaningBn,
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Translation
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FBF9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2EFE7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedTranslation == 'taisirul'
                                    ? (ayah.translationTaisirul ?? '')
                                    : (ayah.translationZakaria ?? ''),
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _selectedTranslation == 'taisirul' ? '— তাইসীরুল কুরআন' : '— ড. আবু বকর যাকারিয়া',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
