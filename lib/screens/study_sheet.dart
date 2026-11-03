import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _showWordByWord = true;
  String _selectedTranslation = 'taisirul'; // 'taisirul' or 'zakaria'
  bool _hasScrolledToInitial = false;

  @override
  void initState() {
    super.initState();
    _ayahsFuture = QuranDbHelper.instance.getAyahsForSurah(widget.surah.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                        _buildTafsirContent(tafsirs['ahsanul_bayan'], scrollController),
                        _buildTafsirContent(tafsirs['ibn_kathir'], scrollController),
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

  Widget _buildTafsirContent(String? rawHtml, ScrollController scrollController) {
    if (rawHtml == null || rawHtml.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('এই আয়াতের জন্য তাফসীর উপলব্ধ নয়।'),
        ),
      );
    }

    final cleanText = rawHtml
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        cleanText,
        style: GoogleFonts.notoSansBengali(
          fontSize: 15,
          height: 1.8,
          color: Colors.black87,
        ),
      ),
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
                      widget.initialAyahNumber > 1
                          ? '${widget.surah.nameEn} • আয়াত ${widget.initialAyahNumber} থেকে শুরু • ${widget.surah.revelationType}'
                          : '${widget.surah.nameEn} • ${widget.surah.totalAyahs} আয়াত • ${widget.surah.revelationType}',
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

                if (!_hasScrolledToInitial && widget.initialAyahNumber > 1) {
                  _hasScrolledToInitial = true;
                  final targetIndex = ayahs.indexWhere((a) => a.ayahNumber == widget.initialAyahNumber);
                  if (targetIndex > 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        final targetOffset = (targetIndex * 250.0).clamp(0.0, _scrollController.position.maxScrollExtent);
                        _scrollController.animateTo(
                          targetOffset,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  }
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: ayahs.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final ayah = ayahs[index];
                    final isInitial = ayah.ayahNumber == widget.initialAyahNumber;

                    return Container(
                      padding: isInitial ? const EdgeInsets.all(8) : EdgeInsets.zero,
                      decoration: isInitial
                          ? BoxDecoration(
                              color: const Color(0xFF0F5132).withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF0F5132).withOpacity(0.2),
                                width: 1.5,
                              ),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ayah number badge & actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
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
                                  if (isInitial && widget.initialAyahNumber > 1) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F5132),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'পৃষ্ঠার শুরু',
                                        style: GoogleFonts.notoSansBengali(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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
