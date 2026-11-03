import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../database/quran_db_helper.dart';
import '../models/surah.dart';
import 'study_sheet.dart';
import 'search_screen.dart';

class MushafViewScreen extends StatefulWidget {
  final int initialPage;

  const MushafViewScreen({super.key, required this.initialPage});

  @override
  State<MushafViewScreen> createState() => _MushafViewScreenState();
}

class _MushafViewScreenState extends State<MushafViewScreen> {
  late PageController _pageController;
  late int _currentPage;
  bool _isUiVisible = true;
  bool _isBookmarked = false;
  List<Surah> _surahs = [];
  Map<int, Map<String, dynamic>> _pagesInfo = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadSurahs();
    _checkBookmarkStatus();
    _saveCurrentLastRead();
  }

  void _loadSurahs() async {
    final list = await QuranDbHelper.instance.getAllSurahs();
    final pMap = await QuranDbHelper.instance.getAllPagesInfo();
    if (mounted) {
      setState(() {
        _surahs = list;
        _pagesInfo = pMap;
      });
      _saveCurrentLastRead();
    }
  }

  void _checkBookmarkStatus() async {
    final status = await QuranDbHelper.instance.isBookmarked(_currentPage);
    if (mounted) {
      setState(() {
        _isBookmarked = status;
      });
    }
  }

  void _saveCurrentLastRead() async {
    final s = _getCurrentSurah(_currentPage);
    final sname = s?.nameBn ?? 'সূরা';
    await QuranDbHelper.instance.saveLastRead(_currentPage, sname);
  }

  Surah? _getCurrentSurah(int page) {
    if (_surahs.isEmpty) return null;
    final info = _pagesInfo[page];
    if (info != null && info['start_surah_id'] != null) {
      final startSurahId = info['start_surah_id'] as int;
      final found = _surahs.where((s) => s.id == startSurahId);
      if (found.isNotEmpty) return found.first;
    }
    Surah current = _surahs.first;
    for (var s in _surahs) {
      if (page >= s.startPage) {
        current = s;
      } else {
        break;
      }
    }
    return current;
  }

  int _getCurrentJuz(int page) {
    // Standard 30 Juz page boundaries
    final juzStarts = [
      2, 23, 43, 63, 83, 103, 123, 143, 163, 183,
      203, 223, 243, 263, 283, 303, 323, 343, 363, 383,
      403, 423, 443, 463, 483, 503, 523, 543, 563, 587
    ];
    int juz = 1;
    for (int i = 0; i < juzStarts.length; i++) {
      if (page >= juzStarts[i]) {
        juz = i + 1;
      } else {
        break;
      }
    }
    return juz;
  }

  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= 612) {
      _pageController.jumpToPage(pageNumber - 1);
      setState(() {
        _currentPage = pageNumber;
      });
      _checkBookmarkStatus();
      _saveCurrentLastRead();
    }
  }

  void _openStudySheet() {
    final surah = _getCurrentSurah(_currentPage);
    if (surah == null) return;

    final info = _pagesInfo[_currentPage];
    final int initialAyah = (info != null && info['start_ayah_number'] != null)
        ? (info['start_ayah_number'] as int)
        : 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.95,
          minChildSize: 0.35,
          builder: (_, __) => StudySheet(
            surah: surah,
            initialAyahNumber: initialAyah,
          ),
        );
      },
    );
  }

  void _showJumpDialog() {
    final controller = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'পৃষ্ঠা নম্বরে যান (১ - ৬১২)',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'পৃষ্ঠা নম্বর',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final p = int.tryParse(controller.text);
                if (p != null && p >= 1 && p <= 612) {
                  Navigator.pop(ctx);
                  _goToPage(p);
                }
              },
              child: Text('যাও', style: GoogleFonts.notoSansBengali()),
            ),
          ],
        );
      },
    );
  }

  // Bookmark Toggle with Yes/No Prompt
  void _promptBookmarkDialog() {
    final s = _getCurrentSurah(_currentPage);
    final sname = s?.nameBn ?? 'কুরআন শরীফ';
    final juzNum = _getCurrentJuz(_currentPage);

    if (_isBookmarked) {
      // Prompt to Remove
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.bookmark_remove, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text(
                  'বুকমার্ক অপসারণ',
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'পৃষ্ঠা $_currentPage ($sname) ইতিমধ্যে বুকমার্ক করা আছে। আপনি কি এটি মুছে ফেলতে চান?',
              style: GoogleFonts.notoSansBengali(fontSize: 15, height: 1.5),
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
                  await QuranDbHelper.instance.removeBookmark(_currentPage);
                  setState(() {
                    _isBookmarked = false;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('পৃষ্ঠা $_currentPage বুকমার্ক মুছে ফেলা হয়েছে', style: GoogleFonts.notoSansBengali()),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text('হ্যাঁ, মুছুন', style: GoogleFonts.notoSansBengali()),
              ),
            ],
          );
        },
      );
    } else {
      // Prompt to Add
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.bookmark_add, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Text(
                  'বুকমার্ক সংরক্ষণ',
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              'আপনি কি পৃষ্ঠা $_currentPage ($sname) বুকমার্ক হিসেবে সংরক্ষণ করতে চান?',
              style: GoogleFonts.notoSansBengali(fontSize: 15, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('না', style: GoogleFonts.notoSansBengali(color: Colors.grey[700])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5132),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await QuranDbHelper.instance.addBookmark(_currentPage, sname, juzNum);
                  setState(() {
                    _isBookmarked = true;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0F5132),
                        content: Text('পৃষ্ঠা $_currentPage বুকমার্ক সংরক্ষণ করা হয়েছে', style: GoogleFonts.notoSansBengali()),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text('হ্যাঁ, সংরক্ষণ করুন', style: GoogleFonts.notoSansBengali()),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSurah = _getCurrentSurah(_currentPage);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8EE), // Authentic Quran Parchment tone
      appBar: _isUiVisible
          ? AppBar(
              backgroundColor: const Color(0xFF0F5132),
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'সূচীপত্র',
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSurah?.nameBn ?? 'হাফেজী কুরআন',
                    style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'পৃষ্ঠা: $_currentPage / ৬১২',
                    style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? const Color(0xFFD4AF37) : Colors.white,
                  ),
                  tooltip: _isBookmarked ? 'বুকমার্ক সরানো' : 'বুকমার্ক করা',
                  onPressed: _promptBookmarkDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'পৃষ্ঠা শেয়ার করুন',
                  onPressed: () {
                    final s = _getCurrentSurah(_currentPage);
                    final sname = s?.nameBn ?? 'সূরা';
                    final juzNum = _getCurrentJuz(_currentPage);
                    final text = '📖 কুরআন মাজীদ (১৫ লাইন হাফেজী)\n'
                        '• পৃষ্ঠা: ' + _currentPage.toString() + '\n'
                        '• পারা: ' + juzNum.toString() + '\n'
                        '• সূরা: ' + sname + '\n\n'
                        'আল-কুরআন (১৫ লাইন হাফেজী)';
                    Share.share(text);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'অনুসন্ধান',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(
                          onResultSelected: (sid, aid) {
                            final s = _surahs.firstWhere((e) => e.id == sid);
                            _goToPage(s.startPage);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isUiVisible = !_isUiVisible;
          });
        },
        onLongPress: _promptBookmarkDialog, // Long press with Yes/No prompt!
        child: Stack(
          children: [
            Directionality(
              textDirection: TextDirection.rtl, // Authentic Right-to-Left Quran pagination
              child: PageView.builder(
                controller: _pageController,
                itemCount: 612,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index + 1;
                  });
                  _checkBookmarkStatus();
                  _saveCurrentLastRead();
                },
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  final fileName = 'assets/pages/page_${pageNum.toString().padLeft(3, '0')}.jpg';

                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.5,
                    child: Center(
                      child: Image.asset(
                        fileName,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text('পৃষ্ঠা $pageNum লোড করা যায়নি'),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Gold Bookmark Ribbon Indicator when bookmarked
            if (_isBookmarked)
              Positioned(
                top: 0,
                left: 16,
                child: Container(
                  width: 32,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.bookmark, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _isUiVisible
          ? Container(
              color: const Color(0xFF0F5132),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.numbers, color: Colors.white),
                      label: Text(
                        'পৃষ্ঠা লাফান',
                        style: GoogleFonts.notoSansBengali(color: Colors.white),
                      ),
                      onPressed: _showJumpDialog,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37), // Islamic Gold
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.translate),
                      label: Text(
                        'অনুবাদ ও তাফসীর',
                        style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _openStudySheet,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
