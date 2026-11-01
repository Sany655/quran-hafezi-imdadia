import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/quran_db_helper.dart';
import '../models/surah.dart';
import 'study_sheet.dart';
import 'index_screen.dart';
import 'search_screen.dart';

class MushafViewScreen extends StatefulWidget {
  final int initialPage;

  const MushafViewScreen({super.key, this.initialPage = 2});

  @override
  State<MushafViewScreen> createState() => _MushafViewScreenState();
}

class _MushafViewScreenState extends State<MushafViewScreen> {
  late PageController _pageController;
  late int _currentPage;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _isUiVisible = true;
  List<Surah> _surahs = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    // Standard Quran is read Right-to-Left (RTL)
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadSurahs();
  }

  void _loadSurahs() async {
    final list = await QuranDbHelper.instance.getAllSurahs();
    setState(() {
      _surahs = list;
    });
  }

  Surah? _getCurrentSurah(int page) {
    if (_surahs.isEmpty) return null;
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

  void _playPageTurnSound() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/flipsound.mp3'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= 612) {
      _pageController.jumpToPage(pageNumber - 1);
      setState(() {
        _currentPage = pageNumber;
      });
    }
  }

  void _openStudySheet() {
    final surah = _getCurrentSurah(_currentPage);
    if (surah == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.95,
          minChildSize: 0.35,
          builder: (_, __) => StudySheet(surah: surah),
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
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                final p = int.tryParse(controller.text);
                if (p != null && p >= 1 && p <= 612) {
                  Navigator.pop(ctx);
                  _goToPage(p);
                }
              },
              child: const Text('যাও'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
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
                  icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
                  tooltip: 'পৃষ্ঠা উল্টানোর শব্দ',
                  onPressed: () {
                    setState(() {
                      _soundEnabled = !_soundEnabled;
                    });
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
                IconButton(
                  icon: const Icon(Icons.list),
                  tooltip: 'সূচীপত্র',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IndexScreen(onPageSelected: _goToPage),
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
        child: Directionality(
          textDirection: TextDirection.rtl, // Authentic Right-to-Left Quran pagination
          child: PageView.builder(
            controller: _pageController,
            itemCount: 612,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index + 1;
              });
              _playPageTurnSound();
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
