import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ayah.dart';
import '../models/surah.dart';
import '../database/quran_db_helper.dart';
import '../utils/tri_calendar_helper.dart';

class StudySheet extends StatefulWidget {
  final int pageNumber;
  final Surah? surah;
  final int initialAyahNumber;
  final ScrollController? scrollController;

  const StudySheet({
    super.key,
    required this.pageNumber,
    this.surah,
    this.initialAyahNumber = 1,
    this.scrollController,
  });

  @override
  State<StudySheet> createState() => _StudySheetState();
}

class _StudySheetState extends State<StudySheet> {
  late Future<List<Ayah>> _ayahsFuture;
  bool _showWordByWord = true;
  String _selectedTranslation = 'tawzeehul'; // 'tawzeehul', 'shafi', 'taisirul'

  @override
  void initState() {
    super.initState();
    _ayahsFuture = QuranDbHelper.instance.getAyahsForPage(widget.pageNumber);
  }

  void _showTafsirModal(BuildContext context, Ayah ayah) async {
    final tafsirs = await QuranDbHelper.instance.getTafsirForAyah(
      ayah.surahId,
      ayah.ayahNumber,
    );

    if (!context.mounted) return;

    final sName = ayah.surahNameBn ?? widget.surah?.nameBn ?? 'সূরা';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 3,
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
                        Expanded(
                          child: Text(
                            'তাফসীর: $sName (আয়াত ${TriCalendarHelper.toBnNum(ayah.ayahNumber)})',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F5132),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    labelColor: const Color(0xFF0F5132),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: const Color(0xFF0F5132),
                    indicatorWeight: 3,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelStyle: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'তাওযীহুল কুরআন'),
                      Tab(text: 'আহসানুল বায়ান'),
                      Tab(text: 'ইবনে কাসীর'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTafsirContent(tafsirs['tawzeehul_quran'], scrollController),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'এই আয়াতের জন্য পৃথক তাফসীর উল্লেখ নেই (পূর্ববর্তী অথবা পরবর্তী আয়াতের সাথে সংযুক্ত হতে পারে)।',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansBengali(color: Colors.grey[600]),
          ),
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
          fontSize: 14,
          height: 1.8,
          color: Colors.black87,
        ),
      ),
    );
  }

  String _getTranslationText(Ayah ayah) {
    switch (_selectedTranslation) {
      case 'tawzeehul':
        return ayah.translationTawzeehul ?? ayah.translationTaisirul ?? '';
      case 'shafi':
        return ayah.translationShafi ?? ayah.translationTaisirul ?? '';
      case 'taisirul':
      default:
        return ayah.translationTaisirul ?? ayah.translationTawzeehul ?? '';
    }
  }

  String _getTranslationLabel() {
    switch (_selectedTranslation) {
      case 'tawzeehul':
        return '(তাফসীরে তাওযীহুল কুরআন - মুফতী তাকী উসমানী)';
      case 'shafi':
        return "(মা'আরিফুল কুরআন - মুফতী শফী রহ.)";
      case 'taisirul':
      default:
        return '(তাইসীরুল কুরআন - তাওহীদ পাবলিকেশন্স)';
    }
  }

  Widget _buildTranslationChip(String key, String label) {
    final isSelected = _selectedTranslation == key;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.notoSansBengali(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF0F5132),
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: const Color(0xFF0F5132),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF0F5132) : const Color(0xFFB7D5C4),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (val) {
        if (val) setState(() => _selectedTranslation = key);
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'পৃষ্ঠা ${TriCalendarHelper.toBnNum(widget.pageNumber)} এর অনুবাদ ও শব্দার্থ',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F5132),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'হাফেজী কোরআন • ১৫ লাইন ভিত্তিক পাতা',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Word by word toggle
                    IconButton(
                      icon: Icon(
                        _showWordByWord ? Icons.view_column : Icons.view_headline,
                        color: const Color(0xFF0F5132),
                      ),
                      tooltip: _showWordByWord ? 'শব্দার্থ বন্ধ করুন' : 'শব্দার্থ দেখুন',
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

          // Translation Switcher Tabs (Scrollable tab boxes bar)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2EFE7), width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate, size: 15, color: Color(0xFF0F5132)),
                      const SizedBox(width: 5),
                      Text(
                        'অনুবাদ:',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F5132),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  _buildTranslationChip('tawzeehul', 'তাওযীহুল কুরআন'),
                  const SizedBox(width: 8),
                  _buildTranslationChip('shafi', "মা'আরিফুল কুরআন"),
                  const SizedBox(width: 8),
                  _buildTranslationChip('taisirul', 'তাইসীরুল কুরআন'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Ayahs List
          Expanded(
            child: FutureBuilder<List<Ayah>>(
              future: _ayahsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0F5132)));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'পৃষ্ঠা ${widget.pageNumber} এর তথ্য লোড করতে সমস্যা হয়েছে',
                            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F5132),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _ayahsFuture = QuranDbHelper.instance.getAyahsForPage(widget.pageNumber);
                              });
                            },
                            child: Text('পুনরায় চেষ্টা করুন', style: GoogleFonts.notoSansBengali()),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book, color: Colors.grey, size: 40),
                          const SizedBox(height: 8),
                          Text('এই পৃষ্ঠার জন্য তথ্য পাওয়া যায়নি', style: GoogleFonts.notoSansBengali()),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F5132),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _ayahsFuture = QuranDbHelper.instance.getAyahsForPage(widget.pageNumber);
                              });
                            },
                            child: Text('পুনরায় লোড করুন', style: GoogleFonts.notoSansBengali()),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final ayahs = snapshot.data!;

                return ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: ayahs.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final ayah = ayahs[index];
                    final isInitial = (index == 0);
                    final isNewSurah = (index == 0 || ayah.surahId != ayahs[index - 1].surahId);
                    final surahTitle = ayah.surahNameBn ?? widget.surah?.nameBn ?? 'সূরা';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Surah Header if new surah starts on this page
                        if (isNewSurah) ...[
                          Container(
                            margin: EdgeInsets.only(bottom: 12, top: index > 0 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F5132),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  surahTitle,
                                  style: GoogleFonts.notoSansBengali(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'পৃষ্ঠা ${TriCalendarHelper.toBnNum(widget.pageNumber)}',
                                  style: GoogleFonts.notoSansBengali(
                                    color: const Color(0xFFFDE68A),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (ayah.ayahNumber == 1 && ayah.surahId != 1 && ayah.surahId != 9) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              alignment: Alignment.center,
                              child: const Text(
                                'بِسۡمِ اللهِ الرَّحۡمٰنِ الرَّحِيۡمِ',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F5132),
                                ),
                              ),
                            ),
                          ],
                        ],

                        // Ayah Card
                        Container(
                          padding: isInitial ? const EdgeInsets.all(10) : EdgeInsets.zero,
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
                              // Top info row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F5132).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$surahTitle • আয়াত ${TriCalendarHelper.toBnNum(ayah.ayahNumber)}',
                                              style: GoogleFonts.notoSansBengali(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0F5132),
                                              ),
                                            ),
                                          ),
                                          if (isInitial) ...[
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
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share, size: 18, color: Color(0xFF0F5132)),
                                        tooltip: 'আয়াত শেয়ার করুন',
                                        onPressed: () {
                                          final bnText = _getTranslationText(ayah);
                                          final text = '﴿ ${ayah.textIndopak} ﴾\n\n'
                                              'বাংলা অর্থ:\n"$bnText"\n\n'
                                              '[সূরা $surahTitle, আয়াত ${TriCalendarHelper.toBnNum(ayah.ayahNumber)}, পৃষ্ঠা ${TriCalendarHelper.toBnNum(widget.pageNumber)}]\n'
                                              'আল-কুরআন';
                                          Share.share(text);
                                        },
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
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Arabic text
                              SelectableText(
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

                              // Translation Text
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
                                    SelectableText(
                                      _getTranslationText(ayah),
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _getTranslationLabel(),
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
