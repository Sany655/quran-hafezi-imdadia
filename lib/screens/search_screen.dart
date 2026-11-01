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
    if (clean.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final res = await QuranDbHelper.instance.searchBengali(clean);
      setState(() {
        _results = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
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
                      hintText: 'শব্দ লিখুন (যেমন: ক্ষমা, সালাত, জান্নাত)...',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF0F5132)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                child: Text(
                  'কোন ফলাফল পাওয়া যায়নি',
                  style: GoogleFonts.notoSansBengali(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            )
          else
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
                        Text(
                          'সূরা $sid',
                          style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey),
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
      ),
    );
  }
}
