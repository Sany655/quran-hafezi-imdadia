import 'package:flutter/material.dart';
import '../database/quran_db_helper.dart';
import '../models/juz.dart';
import '../models/quran_range.dart';
import '../models/surah.dart';

Future<QuranRange?> showQuranRangeSelector(BuildContext context) {
  return showDialog<QuranRange>(
    context: context,
    builder: (_) => const _QuranRangeDialog(),
  );
}

enum _RangeType { surahAyah, juz, page }

class _QuranRangeDialog extends StatefulWidget {
  const _QuranRangeDialog();

  @override
  State<_QuranRangeDialog> createState() => _QuranRangeDialogState();
}

class _QuranRangeDialogState extends State<_QuranRangeDialog> {
  static const _pageCount = 612;

  final _startPageController = TextEditingController(text: '1');
  final _endPageController = TextEditingController(text: '1');
  _RangeType _rangeType = _RangeType.surahAyah;
  List<Surah> _surahs = [];
  List<Juz> _juz = [];
  Map<int, Map<String, dynamic>> _pages = {};
  int _startSurahId = 1;
  int _startAyah = 1;
  int _endSurahId = 1;
  int _endAyah = 7;
  int _startJuz = 1;
  int _endJuz = 1;
  bool _isLoading = true;
  String? _loadError;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    try {
      final db = QuranDbHelper.instance;
      final surahs = await db.getAllSurahs();
      final juz = await db.getAllJuz();
      final pages = await db.getAllPagesInfo();
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _juz = juz;
        _pages = pages;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  int _ayahCount(int surahId) =>
      _surahs.firstWhere((surah) => surah.id == surahId).totalAyahs;

  Map<String, int>? _pointForPage(int page, {required bool end}) {
    final info = _pages[page];
    if (info == null) return null;
    final surahKey = end ? 'end_surah_id' : 'start_surah_id';
    final ayahKey = end ? 'end_ayah_number' : 'start_ayah_number';
    final surah = info[surahKey];
    final ayah = info[ayahKey];
    if (surah is! int || ayah is! int) return null;
    return {'surah': surah, 'ayah': ayah};
  }

  List<int> _pagesForJuz(int juzId) {
    final pageNumbers = _pages.entries
        .where((entry) => entry.value['juz_number'] == juzId)
        .map((entry) => entry.key)
        .toList();
    pageNumbers.sort();
    return pageNumbers;
  }

  Future<QuranRange?> _rangeForPages(int startPage, int endPage) async {
    final start = _pointForPage(startPage, end: false);
    final end = _pointForPage(endPage, end: true);
    if (start == null || end == null) return null;
    return QuranRange(
      startSurahId: start['surah']!,
      startAyahNumber: start['ayah']!,
      endSurahId: end['surah']!,
      endAyahNumber: end['ayah']!,
      startPage: startPage,
      endPage: endPage,
    );
  }

  Future<void> _submit() async {
    try {
      QuranRange? range;
      if (_rangeType == _RangeType.page) {
        final startPage = int.tryParse(_startPageController.text.trim());
        final endPage = int.tryParse(_endPageController.text.trim());
        if (startPage == null ||
            endPage == null ||
            startPage < 1 ||
            endPage > _pageCount ||
            startPage > endPage) {
          setState(() => _validationError = 'পৃষ্ঠা ১–৬১২ এর মধ্যে দিন এবং শুরুর পৃষ্ঠা শেষের আগে রাখুন।');
          return;
        }
        range = await _rangeForPages(startPage, endPage);
      } else if (_rangeType == _RangeType.juz) {
        if (_startJuz > _endJuz) {
          setState(() => _validationError = 'শুরুর পারা শেষের পারার আগে রাখুন।');
          return;
        }
        final startPages = _pagesForJuz(_startJuz);
        final endPages = _pagesForJuz(_endJuz);
        if (startPages.isEmpty || endPages.isEmpty) {
          setState(() => _validationError = 'নির্বাচিত পারার পৃষ্ঠা পাওয়া যায়নি।');
          return;
        }
        range = await _rangeForPages(startPages.first, endPages.last);
      } else {
        final startSurah = _surahs.firstWhere((surah) => surah.id == _startSurahId);
        final endSurah = _surahs.firstWhere((surah) => surah.id == _endSurahId);
        if (_startSurahId > _endSurahId ||
            (_startSurahId == _endSurahId && _startAyah > _endAyah)) {
          setState(() => _validationError = 'শুরুর আয়াত শেষের আয়াতের পরে হতে পারবে না।');
          return;
        }
        final startPage = await QuranDbHelper.instance.getPageForAyah(_startSurahId, _startAyah);
        final endPage = await QuranDbHelper.instance.getPageForAyah(_endSurahId, _endAyah);
        if (startPage == null || endPage == null) {
          setState(() => _validationError = 'নির্বাচিত আয়াতের মুসহাফ পৃষ্ঠা পাওয়া যায়নি।');
          return;
        }
        range = QuranRange(
          startSurahId: startSurah.id,
          startAyahNumber: _startAyah,
          endSurahId: endSurah.id,
          endAyahNumber: _endAyah,
          startPage: startPage,
          endPage: endPage,
        );
      }

      if (range == null) {
        setState(() => _validationError = 'নির্বাচিত পৃষ্ঠার আয়াতের তথ্য পাওয়া যায়নি।');
        return;
      }
      final ayahCounts = {for (final surah in _surahs) surah.id: surah.totalAyahs};
      if (!range.isValid(ayahCounts)) {
        setState(() => _validationError = 'কুরআনের সীমার বাইরে একটি রেঞ্জ নির্বাচন করা হয়েছে।');
        return;
      }
      if (mounted) Navigator.of(context).pop(range);
    } catch (error) {
      if (!mounted) return;
      setState(() => _validationError = 'রেঞ্জ তৈরি করা যায়নি: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('কুরআনের রেঞ্জ নির্বাচন'),
      content: SizedBox(
        width: 440,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Text('কুরআন রেফারেন্স লোড করা যায়নি: $_loadError')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<_RangeType>(
                          value: _rangeType,
                          decoration: const InputDecoration(labelText: 'রেঞ্জের ধরন'),
                          items: const [
                            DropdownMenuItem(value: _RangeType.surahAyah, child: Text('সূরা ও আয়াত')),
                            DropdownMenuItem(value: _RangeType.juz, child: Text('পারা')),
                            DropdownMenuItem(value: _RangeType.page, child: Text('পৃষ্ঠা')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _rangeType = value;
                              _validationError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_rangeType == _RangeType.surahAyah) _buildAyahFields(),
                        if (_rangeType == _RangeType.juz) _buildJuzFields(),
                        if (_rangeType == _RangeType.page) _buildPageFields(),
                        if (_validationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _validationError!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('বাতিল'),
        ),
        FilledButton(
          onPressed: _isLoading || _loadError != null ? null : _submit,
          child: const Text('নির্বাচন করুন'),
        ),
      ],
    );
  }

  Widget _buildAyahFields() {
    return Column(
      children: [
        _buildSurahAyahEndpoint(
          label: 'শুরু',
          surahId: _startSurahId,
          ayah: _startAyah,
          onSurahChanged: (value) {
            if (value == null) return;
            setState(() {
              _startSurahId = value;
              _startAyah = 1;
              _validationError = null;
            });
          },
          onAyahChanged: (value) => setState(() {
            _startAyah = value ?? 1;
            _validationError = null;
          }),
        ),
        const SizedBox(height: 10),
        _buildSurahAyahEndpoint(
          label: 'শেষ',
          surahId: _endSurahId,
          ayah: _endAyah,
          onSurahChanged: (value) {
            if (value == null) return;
            setState(() {
              _endSurahId = value;
              _endAyah = 1;
              _validationError = null;
            });
          },
          onAyahChanged: (value) => setState(() {
            _endAyah = value ?? 1;
            _validationError = null;
          }),
        ),
      ],
    );
  }

  Widget _buildSurahAyahEndpoint({
    required String label,
    required int surahId,
    required int ayah,
    required ValueChanged<int?> onSurahChanged,
    required ValueChanged<int?> onAyahChanged,
  }) {
    final totalAyahs = _ayahCount(surahId);
    final safeAyah = ayah.clamp(1, totalAyahs).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                value: surahId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'সূরা'),
                items: _surahs
                    .map((surah) => DropdownMenuItem(
                          value: surah.id,
                          child: Text('${surah.id}. ${surah.nameBn}', overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: onSurahChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: safeAyah,
                decoration: const InputDecoration(labelText: 'আয়াত'),
                items: List.generate(totalAyahs, (index) => index + 1)
                    .map((number) => DropdownMenuItem(value: number, child: Text('$number')))
                    .toList(),
                onChanged: onAyahChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJuzFields() {
    return Row(
      children: [
        Expanded(child: _juzDropdown('শুরুর পারা', _startJuz, (value) {
          if (value != null) setState(() => _startJuz = value);
        })),
        const SizedBox(width: 10),
        Expanded(child: _juzDropdown('শেষের পারা', _endJuz, (value) {
          if (value != null) setState(() => _endJuz = value);
        })),
      ],
    );
  }

  Widget _juzDropdown(String label, int value, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: _juz
          .map((juz) => DropdownMenuItem(value: juz.id, child: Text(juz.nameBn)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPageFields() {
    return Row(
      children: [
        Expanded(child: _pageTextField('শুরুর পৃষ্ঠা', _startPageController)),
        const SizedBox(width: 10),
        Expanded(child: _pageTextField('শেষের পৃষ্ঠা', _endPageController)),
      ],
    );
  }

  Widget _pageTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, helperText: '১–$_pageCount'),
      onChanged: (_) => setState(() => _validationError = null),
    );
  }
}
