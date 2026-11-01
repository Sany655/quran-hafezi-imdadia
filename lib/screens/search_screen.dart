import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/quran_db_helper.dart';

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

  void _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final res = await QuranDbHelper.instance.searchBengali(clean);
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'বাংলা অনুবাদে খুঁজুন',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F5132),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'সালাত / salat, রোজা / roza, jannat...',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 14),
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
                      if (val.trim().length >= 2) {
                        _performSearch(val);
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_results.length}টি ফলাফল পাওয়া গেছে',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _results[index];
                  final sid = item['surah_id'] as int;
                  final sname = item['name_bn'] as String;
                  final aid = item['ayah_number'] as int;
                  final edition = item['edition'] as String;
                  final text = item['text_bn'] as String;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$sname ($aid)',
                          style: GoogleFonts.notoSansBengali(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5132),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F5132).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            edition == 'taisirul' ? 'তাইসীরুল' : 'যাকারিয়া',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              color: const Color(0xFF0F5132),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        text,
                        style: GoogleFonts.notoSansBengali(fontSize: 14, height: 1.5),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onResultSelected(sid, aid);
                    },
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
