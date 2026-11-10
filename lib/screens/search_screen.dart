import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../database/quran_db_helper.dart';
import '../utils/tri_calendar_helper.dart';

class SearchScreen extends StatefulWidget {
  final Function(int surahId, int ayahNumber) onResultSelected;

  const SearchScreen({super.key, required this.onResultSelected});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _selectedEdition = 'all'; // 'all', 'tawzeehul', 'shafi', 'taisirul'
  final Set<String> _expandedKeys = {};
  Timer? _debounceTimer;

  static const Map<String, String> _editionShortLabels = {
    'tawzeehul': 'তাওযীহুল',
    'shafi': 'মা\'আরিফুল',
    'taisirul': 'তাইসীরুল',
  };

  static const Map<String, String> _editionFullLabels = {
    'tawzeehul': 'তাওযীহুল কুরআন (মুফতী তাকী উসমানী)',
    'shafi': 'মা\'আরিফুল কুরআন (মুফতী শফী রহ.)',
    'taisirul': 'তাইসীরুল কুরআন',
  };

  void _scheduleSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 220), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isLoading = false;
        _expandedKeys.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final res = await QuranDbHelper.instance.searchBengali(
        clean,
        editionFilter: _selectedEdition,
      );
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
          _expandedKeys.clear();
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  TextSpan _buildHighlightedSpan(String text, List<String> terms) {
    final baseStyle = GoogleFonts.notoSansBengali(
      fontSize: 13.5,
      height: 1.55,
      color: Colors.black87,
    );
    final filteredTerms = terms.where((t) => t.trim().length >= 2).toList();
    if (filteredTerms.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final pattern = filteredTerms.map(RegExp.escape).join('|');
    final regex = RegExp(pattern, caseSensitive: false);
    final matches = regex.allMatches(text).toList();
    if (matches.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
      }
      spans.add(TextSpan(
        text: text.substring(m.start, m.end),
        style: TextStyle(
          backgroundColor: const Color(0xFFD4AF37).withOpacity(0.30),
          color: const Color(0xFF0A3622),
          fontWeight: FontWeight.bold,
        ),
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return TextSpan(style: baseStyle, children: spans);
  }

  void _showShareSheet(Map<String, dynamic> item) {
    final sname = item['name_bn'] as String;
    final aid = item['ayah_number'] as int;
    final pageNum = item['page_number'] as int;
    final arabic = (item['text_indopak'] as String?) ?? '';
    final transMap = Map<String, String>.from(item['translations'] as Map? ?? {});

    final available = ['tawzeehul', 'shafi', 'taisirul']
        .where((ed) => (transMap[ed] ?? '').trim().isNotEmpty)
        .toList();

    if (available.isEmpty && arabic.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'আয়াত শেয়ার করুন • $sname (${TriCalendarHelper.toBnNum(aid)})',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F5132),
                  ),
                ),
                const SizedBox(height: 8),
                if (available.length > 1)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF0F5132),
                      child: Icon(Icons.library_books, color: Colors.white, size: 18),
                    ),
                    title: Text(
                      'সবগুলো অনুবাদসহ শেয়ার করুন',
                      style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      'তাওযীহুল, মা\'আরিফুল ও তাইসীরুল একসাথে',
                      style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[600]),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      final buffer = StringBuffer();
                      if (arabic.isNotEmpty) buffer.writeln('﴿ $arabic ﴾\n');
                      for (final ed in available) {
                        buffer.writeln('• ${_editionFullLabels[ed]}:');
                        buffer.writeln('"${transMap[ed]}"\n');
                      }
                      buffer.write('[সূরা $sname, আয়াত ${TriCalendarHelper.toBnNum(aid)}, পৃষ্ঠা ${TriCalendarHelper.toBnNum(pageNum)}]\nআল-কুরআন');
                      Share.share(buffer.toString());
                    },
                  ),
                for (final ed in available)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0F5132).withOpacity(0.1),
                      child: const Icon(Icons.share, color: Color(0xFF0F5132), size: 18),
                    ),
                    title: Text(
                      '${_editionShortLabels[ed]} অনুবাদ শেয়ার করুন',
                      style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      final buffer = StringBuffer();
                      if (arabic.isNotEmpty) buffer.writeln('﴿ $arabic ﴾\n');
                      buffer.writeln('বাংলা অর্থ (${_editionFullLabels[ed]}):');
                      buffer.writeln('"${transMap[ed]}"\n');
                      buffer.write('[সূরা $sname, আয়াত ${TriCalendarHelper.toBnNum(aid)}, পৃষ্ঠা ${TriCalendarHelper.toBnNum(pageNum)}]\nআল-কুরআন');
                      Share.share(buffer.toString());
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'কুরআন অনুসন্ধান (আরবি ও বাংলা)',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF0F5132),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'সালাত যাকাত / salat, রহমান, ২:২৫৫...',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF0F5132)),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _controller.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {});
                      if (val.trim().length >= 2) {
                        _scheduleSearch(val);
                      } else if (val.trim().isEmpty) {
                        _performSearch('');
                      }
                    },
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.arrow_forward),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F5132)),
                  onPressed: () => _performSearch(_controller.text),
                ),
              ],
            ),
          ),
          // Translation edition filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (final entry in const {
                  'all': 'সব অনুবাদ (৩টি)',
                  'tawzeehul': 'তাওযীহুল',
                  'shafi': 'মা\'আরিফুল',
                  'taisirul': 'তাইসীরুল',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        entry.value,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: _selectedEdition == entry.key ? FontWeight.bold : FontWeight.normal,
                          color: _selectedEdition == entry.key ? Colors.white : const Color(0xFF0F5132),
                        ),
                      ),
                      selected: _selectedEdition == entry.key,
                      selectedColor: const Color(0xFF0F5132),
                      backgroundColor: const Color(0xFF0F5132).withOpacity(0.08),
                      showCheckmark: false,
                      onSelected: (_) {
                        if (_selectedEdition != entry.key) {
                          setState(() {
                            _selectedEdition = entry.key;
                          });
                          if (_controller.text.trim().isNotEmpty) {
                            _performSearch(_controller.text);
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_hasSearched && _results.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'কোন ফলাফল পাওয়া যায়নি',
                      style: GoogleFonts.notoSansBengali(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'বানান পরীক্ষা করুন অথবা অন্য কোনো শব্দ দিয়ে চেষ্টা করুন',
                      style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (_results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${TriCalendarHelper.toBnNum(_results.length)}টি আয়াত পাওয়া গেছে',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F5132),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _results[index];
                  final sid = item['surah_id'] as int;
                  final sname = item['name_bn'] as String;
                  final aid = item['ayah_number'] as int;
                  final pageNum = item['page_number'] as int;
                  final arabic = (item['text_indopak'] as String?) ?? '';
                  final matchedEditions = List<String>.from(item['matched_editions'] as List? ?? []);
                  final transMap = Map<String, String>.from(item['translations'] as Map? ?? {});
                  final matchedTerms = List<String>.from(item['matched_terms'] as List? ?? []);
                  final verseKey = '$sid:$aid';
                  final isExpanded = _expandedKeys.contains(verseKey);

                  final displayedEditions = isExpanded
                      ? ['tawzeehul', 'shafi', 'taisirul']
                          .where((ed) => (transMap[ed] ?? '').isNotEmpty)
                          .toList()
                      : (_selectedEdition != 'all' && (transMap[_selectedEdition] ?? '').isNotEmpty)
                          ? [_selectedEdition]
                          : matchedEditions;

                  final hasOtherEditions = !isExpanded &&
                      ['tawzeehul', 'shafi', 'taisirul']
                          .any((ed) => !displayedEditions.contains(ed) && (transMap[ed] ?? '').isNotEmpty);

                  return Card(
                    elevation: 0.8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onResultSelected(sid, aid);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$sname (${TriCalendarHelper.toBnNum(aid)})',
                                    style: GoogleFonts.notoSansBengali(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: const Color(0xFF0F5132),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5132).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'পৃষ্ঠা ${TriCalendarHelper.toBnNum(pageNum)}',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F5132),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 19, color: Color(0xFF0F5132)),
                                  tooltip: 'শেয়ার করুন',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _showShareSheet(item),
                                ),
                              ],
                            ),
                            if (arabic.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                arabic,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 19,
                                  height: 1.7,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            for (final ed in displayedEditions)
                              if ((transMap[ed] ?? '').isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37).withOpacity(0.16),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _editionShortLabels[ed] ?? ed,
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF7A5C00),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: _buildHighlightedSpan(transMap[ed]!, matchedTerms),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            if (hasOtherEditions || isExpanded)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedKeys.remove(verseKey);
                                      } else {
                                        _expandedKeys.add(verseKey);
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                    size: 16,
                                    color: const Color(0xFF0F5132),
                                  ),
                                  label: Text(
                                    isExpanded ? 'সংক্ষিপ্ত করুন' : 'সব ৩টি অনুবাদ দেখুন',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F5132),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
