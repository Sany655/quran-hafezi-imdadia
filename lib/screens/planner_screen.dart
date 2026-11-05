import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../database/quran_db_helper.dart';
import '../models/hifz_model.dart';
import '../models/hafez_model.dart';
import '../models/planner_model.dart';
import '../models/quran_range.dart';
import '../services/planner_service.dart';
import '../utils/tri_calendar_helper.dart';
import 'quran_range_selector.dart';

class PlannerScreen extends StatefulWidget {
  final Function(int pageNumber) onOpenPage;

  const PlannerScreen({
    super.key,
    required this.onOpenPage,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlannerModel? _plannerModel;
  bool _isLoading = true;
  String? _loadError;
  bool _hasSyncedReminder = false;

  DateTime _selectedDate = DateTime.now();
  DateTime _planStartDate = DateTime.now();

  // Integer trackers for Today's Focus
  int _currentParasRead = 0;
  int _currentPagesRead = 0;
  List<QuranRange> _selectedReadingRanges = [];
  final TextEditingController _parasController = TextEditingController(text: '0');
  final TextEditingController _pagesController = TextEditingController(text: '0');

  // Text inputs
  final TextEditingController _generalTilawatController = TextEditingController();
  final TextEditingController _hafizDourController = TextEditingController();
  final TextEditingController _studentSabakController = TextEditingController();
  final TextEditingController _studentSabkiController = TextEditingController();
  final TextEditingController _studentDourController = TextEditingController();

  // Diary / Notes inputs
  final TextEditingController _notePageController = TextEditingController();
  final TextEditingController _noteTextController = TextEditingController();

  // Roadmap inputs
  int _cycleTargetDays = 30;
  int _cycleStartPara = 1;
  int _planStartPage = 1;
  int _pagesPerDay = 20;
  String _roadmapGoalMode = 'days';
  final TextEditingController _targetDaysController = TextEditingController(text: '30');
  final TextEditingController _pagesPerDayController = TextEditingController(text: '20');
  final TextEditingController _startPageController = TextEditingController(text: '1');
  String? _cycleSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _parasController.dispose();
    _pagesController.dispose();
    _generalTilawatController.dispose();
    _hafizDourController.dispose();
    _studentSabakController.dispose();
    _studentSabkiController.dispose();
    _studentDourController.dispose();
    _notePageController.dispose();
    _noteTextController.dispose();
    _targetDaysController.dispose();
    _pagesPerDayController.dispose();
    _startPageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final model = await PlannerService.instance.getPlannerData();
      if (model.carryForwardMissedTasks) {
        await PlannerService.instance.carryForwardMissedTasksForDate(DateTime.now());
      }
      String? reminderWarning;
      if (!_hasSyncedReminder) {
        _hasSyncedReminder = true;
        try {
          final reminderRestored = await PlannerService.instance.restoreSavedReminder();
          if (reminderRestored == false) {
            reminderWarning = 'নোটিফিকেশন অনুমতি নেই, তাই সংরক্ষিত রিমাইন্ডার বন্ধ রাখা হয়েছে।';
          }
        } catch (error) {
          reminderWarning = 'সংরক্ষিত রিমাইন্ডার চালু করা যায়নি: $error';
        }
        try {
          final hifzRemindersRestored =
              await PlannerService.instance.restoreStudentHifzReminders();
          if (!hifzRemindersRestored) {
            reminderWarning = 'নোটিফিকেশন অনুমতি নেই, তাই হিফজ রিমাইন্ডার চালু হয়নি।';
          }
        } catch (error) {
          reminderWarning = 'হিফজ রিমাইন্ডার চালু করা যায়নি: $error';
        }
        try {
          final readerRemindersRestored =
              await PlannerService.instance.restoreReaderSessionReminders();
          if (!readerRemindersRestored) {
            reminderWarning = 'নোটিফিকেশন অনুমতি নেই, তাই রিডিং সেশন রিমাইন্ডার চালু হয়নি।';
          }
        } catch (error) {
          reminderWarning = 'রিডিং সেশন রিমাইন্ডার চালু করা যায়নি: $error';
        }
      }
      if (!mounted) return;
      setState(() {
        _plannerModel = model;
        _isLoading = false;
        _loadError = null;
        _cycleTargetDays = model.targetDays > 0 ? model.targetDays : 30;
        _targetDaysController.text = _cycleTargetDays.toString();
        _pagesPerDay = model.pagesPerDay.clamp(1, PlannerService.totalQuranPages).toInt();
        _pagesPerDayController.text = _pagesPerDay.toString();
        _roadmapGoalMode = model.roadmapGoalMode;
        _planStartPage = model.planStartPage.clamp(1, PlannerService.totalQuranPages).toInt();
        _startPageController.text = _planStartPage.toString();
        _planStartDate = DateTime.tryParse(model.planStartDate ?? '') ?? DateTime.now();
        _updateSelectedDateControllers();
      });
      if (reminderWarning != null) _showSnack(reminderWarning);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  void _updateSelectedDateControllers() {
    if (_plannerModel == null) return;
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();

    _currentParasRead = log.parasRead.clamp(0, 30);
    _currentPagesRead = log.pagesRead.clamp(0, 612);
    _selectedReadingRanges = List<QuranRange>.from(log.readingRanges);

    _parasController.text = _currentParasRead.toString();
    _pagesController.text = _currentPagesRead.toString();

    _generalTilawatController.text = log.generalTilawat ?? log.dourPara ?? '';
    _hafizDourController.text = log.dourPara ?? '';
    _studentSabakController.text = log.sabak ?? '';
    _studentSabkiController.text = log.sabki ?? '';
    _studentDourController.text = log.studentDour ?? '';
  }

  void _changeSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _updateSelectedDateControllers();
    });
  }

  void _setParas(int value) {
    final clamped = value.clamp(0, 30);
    setState(() {
      _currentParasRead = clamped;
      _parasController.text = clamped.toString();
    });
  }

  void _setPages(int value) {
    final clamped = value.clamp(0, 612);
    setState(() {
      _currentPagesRead = clamped;
      _pagesController.text = clamped.toString();
    });
  }

  void _adjustParas(int delta) {
    _setParas(_currentParasRead + delta);
  }

  void _adjustPages(int delta) {
    _setPages(_currentPagesRead + delta);
  }

  void _resetTodayCounters() {
    _setParas(0);
    _setPages(0);
  }

  Future<void> _toggleCurrentDayStatus() async {
    if (_plannerModel == null) return;
    try {
      final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
      final log = _plannerModel!.logs[dateKey] ?? DayLog();
      final currentStatus = log.status;
      final newStatus = (currentStatus == 'completed') ? 'pending' : 'completed';
      log.status = newStatus;
      await PlannerService.instance.saveDayLog(dateKey, log);
      await _loadData();
      if (_loadError == null) {
        _showSnack(
          newStatus == 'completed'
              ? 'আলহামদুলিল্লাহ! পড়া সম্পন্ন চিহ্নিত করা হয়েছে।'
              : 'স্ট্যাটাস পরিবর্তন করা হয়েছে।',
        );
      }
    } catch (error) {
      _showSnack('স্ট্যাটাস সংরক্ষণ করা যায়নি: $error');
    }
  }

  Future<void> _saveDayReading() async {
    if (_plannerModel == null) return;
    try {
      final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
      final log = _plannerModel!.logs[dateKey] ?? DayLog();

      final totalPages = (_currentParasRead * PlannerService.pagesPerPara) + _currentPagesRead;

      log.parasRead = _currentParasRead;
      log.pagesRead = _currentPagesRead;
      log.totalDayPages = totalPages;
      log.readingRanges = List<QuranRange>.from(_selectedReadingRanges);

      if (totalPages > 0) {
        log.status = 'completed';
      }

      final mode = _plannerModel!.profileMode;
      if (mode == 'general') {
        log.generalTilawat = _generalTilawatController.text.trim();
      } else if (mode == 'hafiz') {
        log.dourPara = _hafizDourController.text.trim();
      } else {
        log.sabak = _studentSabakController.text.trim();
        log.sabki = _studentSabkiController.text.trim();
        log.studentDour = _studentDourController.text.trim();
      }

      await PlannerService.instance.saveDayLog(dateKey, log);
      await _loadData();
      if (_loadError == null) _showSnack('আজকের তিলাওয়াত হিসেব সংরক্ষিত হয়েছে!');
    } catch (error) {
      _showSnack('তিলাওয়াতের হিসেব সংরক্ষণ করা যায়নি: $error');
    }
  }

  void _addNote() async {
    final page = int.tryParse(_notePageController.text.trim());
    final text = _noteTextController.text.trim();
    if (page == null || page < 1 || page > 612) {
      _showSnack('সঠিক পৃষ্ঠা নম্বর দিন (১ থেকে ৬১২)');
      return;
    }
    if (text.isEmpty) {
      _showSnack('নোটের বিবরণ লিখুন');
      return;
    }
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    try {
      await PlannerService.instance.addNote(dateKey, page, text);
      _noteTextController.clear();
      await _loadData();
      if (_loadError == null) _showSnack('নোট যুক্ত হয়েছে!');
    } catch (error) {
      _showSnack('নোট সংরক্ষণ করা যায়নি: $error');
    }
  }

  Future<void> _deleteNote(PlannerNote note) async {
    try {
      await PlannerService.instance.deleteNote(note.dateKey, note.id);
      await _loadData();
      if (_loadError == null) _showSnack('নোট মুছে ফেলা হয়েছে');
    } catch (error) {
      _showSnack('নোট মুছে ফেলা যায়নি: $error');
    }
  }

  Future<void> _addReadingRange() async {
    final range = await showQuranRangeSelector(context);
    if (range == null || !mounted) return;
    setState(() => _selectedReadingRanges.add(range));
  }

  void _removeReadingRange(QuranRange range) {
    setState(() => _selectedReadingRanges.remove(range));
  }

  Future<void> _useLastReadPage() async {
    try {
      final lastRead = await QuranDbHelper.instance.getLastRead();
      final page = int.tryParse(lastRead?['page_number']?.toString() ?? '');
      if (page == null || page < 1 || page > PlannerService.totalQuranPages) {
        _showSnack('আগের পড়ার অবস্থান পাওয়া যায়নি।');
        return;
      }
      if (!mounted) return;
      setState(() {
        _planStartPage = page;
        _startPageController.text = page.toString();
        final maxDays = PlannerService.totalQuranPages - page + 1;
        if (_plannerModel?.profileMode == 'general' &&
            _roadmapGoalMode == 'days' &&
            _cycleTargetDays > maxDays) {
          _cycleTargetDays = maxDays;
          _targetDaysController.text = maxDays.toString();
        }
      });
    } catch (error) {
      _showSnack('আগের পড়ার অবস্থান লোড করা যায়নি: $error');
    }
  }

  Future<void> _editReadingSession([ReadingSession? session]) async {
    final titleController = TextEditingController(text: session?.title ?? '');
    var sessionTime = session?.time ?? '06:00';
    var reminderEnabled = session?.reminderEnabled ?? false;
    String? titleError;
    final result = await showDialog<ReadingSession>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            session == null ? 'রিডিং সেশন যোগ করুন' : 'রিডিং সেশন সম্পাদনা',
            style: GoogleFonts.notoSansBengali(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                onChanged: (_) {
                  if (titleError != null) setDialogState(() => titleError = null);
                },
                decoration: InputDecoration(
                  labelText: 'সেশনের নাম',
                  errorText: titleError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text('$sessionTime · সময় নির্বাচন', style: GoogleFonts.notoSansBengali()),
                onPressed: () async {
                  final parts = sessionTime.split(':').map(int.tryParse).toList();
                  final hour = parts.length == 2 ? parts[0] : null;
                  final minute = parts.length == 2 ? parts[1] : null;
                  final initialTime = hour != null &&
                          minute != null &&
                          hour >= 0 &&
                          hour <= 23 &&
                          minute >= 0 &&
                          minute <= 59
                      ? TimeOfDay(hour: hour, minute: minute)
                      : const TimeOfDay(hour: 6, minute: 0);
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: initialTime,
                  );
                  if (selected != null) {
                    setDialogState(() {
                      sessionTime = '${selected.hour.toString().padLeft(2, '0')}:'
                          '${selected.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('এই সেশনের রিমাইন্ডার', style: GoogleFonts.notoSansBengali()),
                value: reminderEnabled,
                onChanged: (enabled) {
                  setDialogState(() => reminderEnabled = enabled);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  setDialogState(() => titleError = 'সেশনের নাম লিখুন।');
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  ReadingSession(
                    id: session?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                    title: title,
                    time: sessionTime,
                    reminderEnabled: reminderEnabled,
                  ),
                );
              },
              child: Text('সংরক্ষণ', style: GoogleFonts.notoSansBengali()),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    if (result == null || !mounted) return;

    final sessions = List<ReadingSession>.from(_plannerModel!.readerSessions);
    final index = sessions.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      sessions.add(result);
    } else {
      sessions[index] = result;
    }
    try {
      await PlannerService.instance.setReadingSessions(sessions);
      bool? remindersScheduled;
      Object? reminderError;
      try {
        remindersScheduled = await PlannerService.instance.restoreReaderSessionReminders();
      } catch (error) {
        reminderError = error;
      }
      if (!mounted) return;
      setState(() => _plannerModel!.readerSessions = sessions);
      _showSnack(
        reminderError != null
            ? 'রিডিং সেশন সংরক্ষিত হয়েছে, তবে রিমাইন্ডার চালু করা যায়নি: $reminderError'
            : remindersScheduled == false
                ? 'রিডিং সেশন সংরক্ষিত হয়েছে, তবে নোটিফিকেশন অনুমতি না থাকায় রিমাইন্ডার চালু হয়নি।'
                : 'রিডিং সেশন সংরক্ষিত হয়েছে। রোডম্যাপ নতুন করে তৈরি করুন।',
      );
    } catch (error) {
      _showSnack('রিডিং সেশন সংরক্ষণ করা যায়নি: $error');
    }
  }

  Future<void> _deleteReadingSession(ReadingSession session) async {
    final sessions = _plannerModel!.readerSessions.where((item) => item.id != session.id).toList();
    if (sessions.isEmpty) {
      _showSnack('কমপক্ষে একটি রিডিং সেশন রাখতে হবে।');
      return;
    }
    try {
      await PlannerService.instance.setReadingSessions(sessions);
      bool? remindersScheduled;
      Object? reminderError;
      try {
        remindersScheduled = await PlannerService.instance.restoreReaderSessionReminders();
      } catch (error) {
        reminderError = error;
      }
      if (!mounted) return;
      setState(() => _plannerModel!.readerSessions = sessions);
      _showSnack(
        reminderError != null
            ? 'রিডিং সেশন মুছে ফেলা হয়েছে, তবে রিমাইন্ডার হালনাগাদ করা যায়নি: $reminderError'
            : remindersScheduled == false
                ? 'রিডিং সেশন মুছে ফেলা হয়েছে, তবে নোটিফিকেশন অনুমতি না থাকায় রিমাইন্ডার চালু হয়নি।'
                : 'রিডিং সেশন মুছে ফেলা হয়েছে। রোডম্যাপ নতুন করে তৈরি করুন।',
      );
    } catch (error) {
      _showSnack('রিডিং সেশন মুছে ফেলা যায়নি: $error');
    }
  }

  Future<void> _toggleReadingSession(ReadingSessionAssignment session) async {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    final previousSessions = List<ReadingSessionAssignment>.from(log.readingSessions);
    final sessions = log.readingSessions.map((item) {
      return item.id == session.id
          ? item.copyWith(completed: !item.completed)
          : item;
    }).toList();
    log.readingSessions = sessions;
    try {
      await PlannerService.instance.saveDayLog(dateKey, log);
      if (!mounted) return;
      setState(() => _plannerModel!.logs[dateKey] = log);
    } catch (error) {
      log.readingSessions = previousSessions;
      _showSnack('সেশনের অগ্রগতি সংরক্ষণ করা যায়নি: $error');
    }
  }

  String _readingRangeLabel(QuranRange range) {
    final start = '${TriCalendarHelper.toBnNum(range.startSurahId)}:'
        '${TriCalendarHelper.toBnNum(range.startAyahNumber)}';
    final end = '${TriCalendarHelper.toBnNum(range.endSurahId)}:'
        '${TriCalendarHelper.toBnNum(range.endAyahNumber)}';
    final pages = range.startPage == range.endPage
        ? TriCalendarHelper.toBnNum(range.startPage)
        : '${TriCalendarHelper.toBnNum(range.startPage)}–'
            '${TriCalendarHelper.toBnNum(range.endPage)}';
    return '$start – $end · পৃষ্ঠা $pages';
  }

  void _setTargetDays(int days) {
    final mode = _plannerModel?.profileMode;
    final maxDays = mode == 'hafiz'
        ? 30
        : mode == 'general'
            ? PlannerService.totalQuranPages - _planStartPage + 1
            : PlannerService.totalQuranPages;
    final validDays = days.clamp(1, maxDays).toInt();
    setState(() {
      _cycleTargetDays = validDays;
      _targetDaysController.text = validDays.toString();
    });
  }

  void _generateCycle() async {
    if (_plannerModel == null) return;
    try {
      final mode = _plannerModel!.profileMode;
      final enteredDays = int.tryParse(_targetDaysController.text.trim()) ?? _cycleTargetDays;
      final enteredPages = int.tryParse(_pagesPerDayController.text.trim()) ?? _pagesPerDay;
      final parsedStartPage = int.tryParse(_startPageController.text.trim());
      if (mode == 'general' &&
          (parsedStartPage == null ||
              parsedStartPage < 1 ||
              parsedStartPage > PlannerService.totalQuranPages)) {
        _showSnack('শুরুর পৃষ্ঠা ১ থেকে ৬১২ এর মধ্যে দিন।');
        return;
      }
      final enteredStartPage = parsedStartPage ?? _planStartPage;
      final remainingPages = PlannerService.totalQuranPages - enteredStartPage + 1;
      final validTargetDays = mode == 'hafiz'
          ? enteredDays.clamp(1, 30).toInt()
          : _roadmapGoalMode == 'pages'
              ? (remainingPages / enteredPages.clamp(1, PlannerService.totalQuranPages)).ceil()
              : enteredDays.clamp(
                  1,
                  mode == 'general' ? remainingPages : PlannerService.totalQuranPages,
                ).toInt();

      await PlannerService.instance.generatePlan(
        mode: mode,
        targetDays: validTargetDays,
        pagesPerDay: enteredPages,
        goalMode: _roadmapGoalMode,
        startPara: _cycleStartPara,
        startDate: _planStartDate,
        startPage: enteredStartPage,
      );
      await _loadData();
      if (_loadError != null || !mounted) return;
      setState(() {
        _cycleTargetDays = validTargetDays;
        if (mode == 'general') _planStartPage = enteredStartPage;
        _cycleSummary =
            mode == 'general'
                ? 'আলহামদুলিল্লাহ! ${TriCalendarHelper.toBnNum(validTargetDays)} দিনের রিডিং প্ল্যান তৈরি হয়েছে। পুরোনো হিসেব অক্ষত রাখা হয়েছে।'
                : 'আলহামদুলিল্লাহ! ${TriCalendarHelper.toBnNum(validTargetDays)} দিনের রোডম্যাপ তৈরি হয়েছে।';
      });
      _showSnack('নতুন রোডম্যাপ তৈরি সম্পন্ন!');
    } catch (error) {
      _showSnack('রোডম্যাপ তৈরি করা যায়নি: $error');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.notoSansBengali()),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F5132),
      ),
    );
  }

  Future<void> _showImportBackupDialog({bool closeSettingsOnSuccess = false}) async {
    final controller = TextEditingController();
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ব্যাকআপ ইমপোর্ট', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আগের ব্যাকআপের JSON এখানে পেস্ট করুন। ইমপোর্ট করলে বর্তমান প্ল্যানার ডেটা প্রতিস্থাপিত হবে।',
              style: GoogleFonts.notoSansBengali(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 5,
              maxLines: 9,
              decoration: InputDecoration(
                hintText: '{"profileMode":"general","logs":{...}}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('ইমপোর্ট করুন', style: GoogleFonts.notoSansBengali()),
          ),
        ],
      ),
    );
    if (shouldImport != true) {
      controller.dispose();
      return;
    }

    try {
      final result = await PlannerService.instance.importBackup(controller.text);
      await _loadData();
      if (_loadError == null) {
        if (closeSettingsOnSuccess && mounted) Navigator.pop(context);
        _showSnack(
          result.reminderScheduled
              ? 'ব্যাকআপ সফলভাবে ইমপোর্ট হয়েছে।'
              : result.reminderError != null
                  ? 'ব্যাকআপ ইমপোর্ট হয়েছে, তবে রিমাইন্ডার সেটিং কার্যকর করা যায়নি: ${result.reminderError}'
                  : 'ব্যাকআপ ইমপোর্ট হয়েছে, তবে নোটিফিকেশন অনুমতি না থাকায় রিমাইন্ডার চালু হয়নি।',
        );
      }
    } catch (error) {
      _showSnack('ব্যাকআপ ইমপোর্ট করা যায়নি: $error');
    } finally {
      controller.dispose();
    }
  }

  void _showSettingsDialog() {
    if (_plannerModel == null) return;
    String selectedMode = _plannerModel!.profileMode;
    int currentOffset = _plannerModel!.hijriOffset;
    bool reminderEnabled = _plannerModel!.reminderEnabled;
    String reminderTime = _plannerModel!.reminderTime;
    bool carryForwardMissedTasks = _plannerModel!.carryForwardMissedTasks;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.settings, color: Color(0xFF0F5132)),
                            const SizedBox(width: 8),
                            Text(
                              'প্ল্যানার সেটিংস ও প্রোফাইল',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F5132),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    Text(
                      'আপনার প্রোফাইল মোড নির্ধারণ করুন:',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModeTile(
                      title: 'সাধারণ তিলাওয়াতকারী',
                      subtitle: 'দৈনিক তিলাওয়াত ও খতম প্ল্যানার',
                      value: 'general',
                      groupValue: selectedMode,
                      onChanged: (val) {
                        setModalState(() => selectedMode = val!);
                      },
                    ),
                    _buildModeTile(
                      title: 'হিফজ শিক্ষার্থী',
                      subtitle: 'মুখস্থের তালিকা, সবক, সবকি ও মনজিল',
                      value: 'student',
                      groupValue: selectedMode,
                      onChanged: (val) {
                        setModalState(() => selectedMode = val!);
                      },
                    ),
                    _buildModeTile(
                      title: 'হুফ্ফাজ মোড',
                      subtitle: 'মঞ্জিল ও দাওর সাইকেল ট্র্যাকার',
                      value: 'hafiz',
                      groupValue: selectedMode,
                      onChanged: (val) {
                        setModalState(() => selectedMode = val!);
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'দৈনিক তিলাওয়াত রিমাইন্ডার:',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.alarm_rounded,
                                color: reminderEnabled ? const Color(0xFF0F5132) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reminderEnabled ? 'রিমাইন্ডার সক্রিয় ($reminderTime)' : 'রিমাইন্ডার বন্ধ',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: reminderEnabled,
                            activeColor: const Color(0xFF0F5132),
                            onChanged: (val) {
                              setModalState(() => reminderEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (reminderEnabled) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(
                          'সময় পরিবর্তন করুন ($reminderTime)',
                          style: GoogleFonts.notoSansBengali(fontSize: 12),
                        ),
                        onPressed: () async {
                          final parts = reminderTime.split(':');
                          final initHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 6 : 6;
                          final initMin = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: initHour, minute: initMin),
                          );
                          if (t != null) {
                            final h = t.hour.toString().padLeft(2, '0');
                            final m = t.minute.toString().padLeft(2, '0');
                            setModalState(() {
                              reminderTime = '$h:$m';
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF0F5132),
                      title: Text(
                        'অসম্পন্ন কাজ পরের দিনে নিন',
                        style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'পরের দিনের তালিকায় কপি হবে; মূল দিনের ইতিহাস অপরিবর্তিত থাকবে।',
                        style: GoogleFonts.notoSansBengali(fontSize: 11),
                      ),
                      value: carryForwardMissedTasks,
                      onChanged: (value) => setModalState(() => carryForwardMissedTasks = value),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'হিজরি তারিখ সমন্বয় (+/- দিন):',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setModalState(() => currentOffset -= 1);
                          },
                        ),
                        Text(
                          '${currentOffset >= 0 ? '+' : ''}${TriCalendarHelper.toBnNum(currentOffset)} দিন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5132),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setModalState(() => currentOffset += 1);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share, size: 16),
                            label: Text('ব্যাকআপ নিন', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                            onPressed: () async {
                              try {
                                final jsonStr = await PlannerService.instance.exportBackup();
                                await Share.share(jsonStr, subject: 'কুরআন প্ল্যানার ব্যাকআপ ডেটা');
                              } catch (error) {
                                _showSnack('ব্যাকআপ তৈরি করা যায়নি: $error');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.red),
                            label: Text(
                              'রিসেট করুন',
                              style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.red),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: Text('প্রগ্রেস রিসেট', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                                  content: Text('আপনি কি সকল ট্র্যাকিং হিসেব রিসেট করতে চান?', style: GoogleFonts.notoSansBengali()),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('না')),
                                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('হ্যাঁ, রিসেট করুন')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await PlannerService.instance.resetProgress();
                                  await _loadData();
                                  if (_loadError == null) {
                                    if (context.mounted) Navigator.pop(ctx);
                                    _showSnack('প্ল্যানার রিসেট সম্পন্ন হয়েছে!');
                                  }
                                } catch (error) {
                                  _showSnack('প্ল্যানার রিসেট করা যায়নি: $error');
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.file_upload_outlined, size: 17),
                        label: Text('ব্যাকআপ ইমপোর্ট করুন', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                        onPressed: () => _showImportBackupDialog(closeSettingsOnSuccess: true),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          try {
                            await PlannerService.instance.setProfileMode(selectedMode);
                            await PlannerService.instance.setHijriOffset(currentOffset);
                            await PlannerService.instance.setCarryForwardMissedTasks(carryForwardMissedTasks);
                            final reminderScheduled = await PlannerService.instance.setReminderSettings(
                              enabled: reminderEnabled,
                              time: reminderTime,
                            );
                            await _loadData();
                            if (context.mounted) Navigator.pop(ctx);
                            _showSnack(
                              reminderEnabled && !reminderScheduled
                                  ? 'নোটিফিকেশন অনুমতি নেই, তাই রিমাইন্ডার সক্রিয় করা যায়নি।'
                                  : 'সেটিংস সংরক্ষিত হয়েছে!',
                            );
                          } catch (error) {
                            _showSnack('সেটিংস সংরক্ষণ করা যায়নি: $error');
                          }
                        },
                        child: Text(
                          'সংরক্ষণ করুন',
                          style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFF0F5132) : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFF0F5132),
        dense: true,
        title: Text(
          title,
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F5132),
          title: Text('কুরআন রুটিন ও প্ল্যানার', style: GoogleFonts.notoSansBengali(color: Colors.white)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F5132)),
        ),
      );
    }
    if (_loadError != null || _plannerModel == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F5132),
          foregroundColor: Colors.white,
          title: Text('কুরআন রুটিন ও প্ল্যানার', style: GoogleFonts.notoSansBengali()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  'প্ল্যানারের ডেটা লোড করা যায়নি। আপনার সংরক্ষিত ডেটা অক্ষত রাখা হয়েছে।',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansBengali(),
                ),
                const SizedBox(height: 8),
                SelectableText(_loadError ?? 'অজানা ত্রুটি'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text('আবার চেষ্টা করুন', style: GoogleFonts.notoSansBengali()),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _showImportBackupDialog,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: Text('ব্যাকআপ থেকে পুনরুদ্ধার', style: GoogleFonts.notoSansBengali()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final mode = _plannerModel!.profileMode;
    final hijriOffset = _plannerModel!.hijriOffset;

    String appTitle;
    if (mode == 'general') {
      appTitle = 'কুরআন তিলাওয়াত ট্র্যাকার';
    } else if (mode == 'student') {
      appTitle = 'হিফজ শিক্ষার্থী রুটিন';
    } else {
      appTitle = 'হুফ্ফাজ দাওর ট্র্যাকার';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F5132),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appTitle,
          style: GoogleFonts.notoSansBengali(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'প্ল্যানার সেটিংস',
            onPressed: _showSettingsDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFF0B3D26),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'নির্বাচিত দিন: ${TriCalendarHelper.formatTriDateFull(_selectedDate, hijriOffset)}',
                        style: GoogleFonts.notoSansBengali(
                          color: const Color(0xFFFDE68A),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'অফলাইন',
                        style: GoogleFonts.notoSansBengali(
                          color: const Color(0xFF0F5132),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF0F5132),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF0F5132),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.notoSansBengali(fontSize: 12),
                  tabs: const [
                    Tab(text: 'আজকের ফোকাস'),
                    Tab(text: 'রোডম্যাপ ও প্ল্যান'),
                    Tab(text: 'কুরআনিক ডায়েরি'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayFocusTab(mode),
          _buildRoadmapTab(mode),
          _buildDiaryTab(mode),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: TODAY'S FOCUS (আজকের ফোকাস)
  // ----------------------------------------------------
  Widget _buildTodayFocusTab(String mode) {
    if (mode == 'student') return _buildStudentHifzTab();
    if (mode == 'hafiz') return _buildHafezTab();

    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    final isCompleted = log.status == 'completed';
    final isToday = dateKey == TriCalendarHelper.formatDateKey(DateTime.now());
    final dayLabel = isToday ? 'আজকের' : 'নির্বাচিত দিনের';

    final stats = PlannerService.instance.calculateKhatamStats(_plannerModel!);
    final totalDayPages = (_currentParasRead * PlannerService.pagesPerPara) + _currentPagesRead;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Horizontal Date Strip
          _buildHorizontalDateStrip(),
          const SizedBox(height: 16),

          // 2. Today's Action Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: isCompleted ? const Color(0xFF0F5132) : Colors.grey[200]!,
                width: isCompleted ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode == 'general'
                              ? '$dayLabel তিলাওয়াত হিসেব'
                              : mode == 'student'
                                  ? '$dayLabel সবক ও পৃষ্ঠা হিসেব'
                                  : '$dayLabel দাওর ও পৃষ্ঠা হিসেব',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5132),
                          ),
                        ),
                        Text(
                          TriCalendarHelper.formatTriDateFull(_selectedDate, _plannerModel!.hijriOffset),
                          style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isCompleted ? const Color(0xFF0F5132) : Colors.grey[400],
                        size: 32,
                      ),
                      tooltip: isCompleted ? 'পড়া সম্পন্ন' : 'অসম্পন্ন',
                      onPressed: _toggleCurrentDayStatus,
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Integer Input: Paras & Pages
                Text(
                  'তিলাওয়াতকৃত পরিমাণ (পূর্ণাঙ্গ পৃষ্ঠা হিসেব):',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),

                // Stepper Row: Paras & Pages
                Row(
                  children: [
                    // Paras Counter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'পারা (১ পারা = ২০ পৃষ্ঠা)',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStepperButton(
                                  icon: Icons.remove,
                                  onPressed: () => _adjustParas(-1),
                                ),
                                SizedBox(
                                  width: 56,
                                  child: TextField(
                                    controller: _parasController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                                      border: InputBorder.none,
                                    ),
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F5132),
                                    ),
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val) ?? 0;
                                      setState(() {
                                        _currentParasRead = parsed.clamp(0, 30);
                                      });
                                    },
                                  ),
                                ),
                                _buildStepperButton(
                                  icon: Icons.add,
                                  onPressed: () => _adjustParas(1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Pages Counter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'পৃষ্ঠা (০ - ৬১২)',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStepperButton(
                                  icon: Icons.remove,
                                  onPressed: () => _adjustPages(-1),
                                ),
                                SizedBox(
                                  width: 56,
                                  child: TextField(
                                    controller: _pagesController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                                      border: InputBorder.none,
                                    ),
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F5132),
                                    ),
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val) ?? 0;
                                      setState(() {
                                        _currentPagesRead = parsed.clamp(0, 612);
                                      });
                                    },
                                  ),
                                ),
                                _buildStepperButton(
                                  icon: Icons.add,
                                  onPressed: () => _adjustPages(1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Addition Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickChip('+৫ পৃষ্ঠা', () => _adjustPages(5)),
                    _buildQuickChip('+১০ পৃষ্ঠা', () => _adjustPages(10)),
                    _buildQuickChip('+১ পারা', () => _adjustParas(1)),
                    _buildQuickChip('+২ পারা', () => _adjustParas(2)),
                    _buildQuickChip('রিসেট', _resetTodayCounters, isDestructive: true),
                  ],
                ),
                const SizedBox(height: 12),

                // Live Calculation Dynamic Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0F5132).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories_rounded, color: Color(0xFF0F5132), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'আজকের সর্বমোট তিলাওয়াত: ${TriCalendarHelper.toBnNum(totalDayPages)} পৃষ্ঠা (${TriCalendarHelper.toBnNum(_currentParasRead)} পারা ${TriCalendarHelper.toBnNum(_currentPagesRead)} পৃষ্ঠা)',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5132),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (mode == 'general' && log.readingSessions.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'আজকের রিডিং সেশন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5132),
                          ),
                        ),
                        Text(
                          'সেশন সম্পন্ন চিহ্নিত করা এবং পড়া পৃষ্ঠার হিসেব আলাদাভাবে সংরক্ষিত হয়।',
                          style: GoogleFonts.notoSansBengali(fontSize: 10, color: Colors.grey[600]),
                        ),
                        ...log.readingSessions.map(
                          (session) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              session.completed ? Icons.check_circle : Icons.menu_book_outlined,
                              color: session.completed ? const Color(0xFF0F5132) : Colors.grey[500],
                            ),
                            title: Text(
                              session.title,
                              style: GoogleFonts.notoSansBengali(fontSize: 12),
                            ),
                            subtitle: Text(
                              '${session.time} · পৃষ্ঠা ${TriCalendarHelper.toBnNum(session.startPage)}'
                              '${session.startPage == session.endPage ? '' : '–${TriCalendarHelper.toBnNum(session.endPage)}'}'
                              '${session.originalDateKey == null ? '' : ' · মূল তারিখ ${session.originalDateKey}'}',
                              style: GoogleFonts.notoSansBengali(fontSize: 10.5, color: Colors.grey[600]),
                            ),
                            onTap: () => widget.onOpenPage(session.startPage),
                            trailing: IconButton(
                              tooltip: session.completed ? 'অসম্পন্ন চিহ্নিত করুন' : 'সম্পন্ন চিহ্নিত করুন',
                              icon: Icon(
                                session.completed ? Icons.undo_rounded : Icons.done_rounded,
                                color: const Color(0xFF0F5132),
                              ),
                              onPressed: () => _toggleReadingSession(session),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (mode == 'general') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'পঠিত কুরআন রেঞ্জ (ঐচ্ছিক):',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addReadingRange,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('রেঞ্জ যোগ', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                      ),
                    ],
                  ),
                  Text(
                    'রেঞ্জটি রেফারেন্স হিসেবে সংরক্ষিত হবে; পৃষ্ঠা কাউন্ট আলাদাভাবে দিন।',
                    style: GoogleFonts.notoSansBengali(fontSize: 10, color: Colors.grey[600]),
                  ),
                  if (_selectedReadingRanges.isNotEmpty)
                    ..._selectedReadingRanges.map(
                      (range) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF0F5132)),
                          title: Text(
                            _readingRangeLabel(range),
                            style: GoogleFonts.notoSansBengali(fontSize: 12),
                          ),
                          onTap: () => widget.onOpenPage(range.startPage),
                          trailing: IconButton(
                            tooltip: 'রেঞ্জ মুছুন',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeReadingRange(range),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],

                // Optional notes or specific mode fields
                if (mode == 'general') ...[
                  Text(
                    'মন্তব্য / পঠিত সূরা বা আয়াত (ঐচ্ছিক):',
                    style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _generalTilawatController,
                    decoration: InputDecoration(
                      hintText: 'যেমন: সূরা আল-ইমরান ১-৫০ আয়াত',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: GoogleFonts.notoSansBengali(fontSize: 12),
                  ),
                ] else if (mode == 'hafiz') ...[
                  Text(
                    'আজকের রিভিশন পারা / সূরার নাম:',
                    style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _hafizDourController,
                    decoration: InputDecoration(
                      hintText: 'যেমন: ৩য় পারা ও ৪র্থ পারা',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: GoogleFonts.notoSansBengali(fontSize: 12),
                  ),
                ] else ...[
                  Text('আজকের সবক:', style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _studentSabakController,
                    decoration: InputDecoration(
                      hintText: 'পৃষ্ঠা বা আয়াতের রেঞ্জ',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: GoogleFonts.notoSansBengali(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text('সবকি ও পেছনের দাওর:', style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _studentSabkiController,
                    decoration: InputDecoration(
                      hintText: 'যেমন: ১ পারা বা পেছনের ৫ পৃষ্ঠা',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: GoogleFonts.notoSansBengali(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text('আজকের আমপারা / পেছনের দাওর:', style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _studentDourController,
                    decoration: InputDecoration(
                      hintText: 'যেমন: আমপারা ১০ পৃষ্ঠা',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: GoogleFonts.notoSansBengali(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),

                // Save and Complete Buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: Text('হিসেব সংরক্ষণ করুন', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5132),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: _saveDayReading,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: Icon(
                        isCompleted ? Icons.check_rounded : Icons.check_box_outline_blank_rounded,
                        size: 16,
                        color: isCompleted ? const Color(0xFF0F5132) : Colors.grey[700],
                      ),
                      label: Text(
                        isCompleted ? 'পড়া সম্পন্ন' : 'সম্পন্ন চিহ্নিত করুন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: isCompleted ? const Color(0xFF0F5132) : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _toggleCurrentDayStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Khatam Progress Card (Valid 612-page percentage math engine)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'চলতি খতমের অগ্রগতি',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F5132),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${TriCalendarHelper.toBnNum(stats.percent.toStringAsFixed(1))}% সম্পন্ন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F5132),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (stats.percent / 100.0).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F5132)),
                  ),
                ),
                const SizedBox(height: 12),

                // Precise Statistics Row 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'পড়া হয়েছে: ${TriCalendarHelper.toBnNum(stats.totalPagesRead)} / ${TriCalendarHelper.toBnNum(stats.totalQuranPages)} পৃষ্ঠা',
                      style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    Text(
                      '(${TriCalendarHelper.toBnNum((stats.totalPagesRead / 20.0).toStringAsFixed(1))} পারা)',
                      style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: const Color(0xFF0F5132), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Precise Statistics Row 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'অবশিষ্ট: ${TriCalendarHelper.toBnNum(stats.remainingPages)} পৃষ্ঠা (~${TriCalendarHelper.toBnNum(stats.remainingParas.toStringAsFixed(1))} পারা)',
                      style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[600]),
                    ),
                    Text(
                      'টার্গেট: ${TriCalendarHelper.toBnNum(stats.targetDays)} দিন (লগ: ${TriCalendarHelper.toBnNum(stats.completedDays)} দিন)',
                      style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (stats.remainingPages > 0) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'টার্গেট অনুযায়ী দৈনিক গতি:',
                        style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${TriCalendarHelper.toBnNum(stats.dailyRequiredPages)} পৃষ্ঠা/দিন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (stats.isCompleted) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCA8A04)),
                    ),
                    child: Text(
                      'মাশাআল্লাহ! আপনার নির্বাচিত তিলাওয়াত লক্ষ্য সম্পন্ন হয়েছে। আল্লাহ কবুল করুন।',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF854D0E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Seven-Day Streak Bar
          _buildSevenDayStreak(),
        ],
      ),
    );
  }

  Widget _buildStudentHifzTab() {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    final settings = _plannerModel!.studentHifzSettings;
    final portions = _plannerModel!.memorizedPortions;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHorizontalDateStrip(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE8DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'হিফজ রুটিন',
                  style: GoogleFonts.notoSansBengali(
                    color: const Color(0xFF0F5132),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${settings.sabaqStartPage > 612 ? 'সবক সম্পন্ন' : 'সবক পৃষ্ঠা ${TriCalendarHelper.toBnNum(settings.sabaqStartPage)} থেকে '
                  '${TriCalendarHelper.toBnNum((settings.sabaqStartPage + settings.sabaqPages - 1).clamp(1, 612))}'} · '
                  'স্মরণে ${TriCalendarHelper.toBnNum(portions.length)}টি অংশ',
                  style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          await PlannerService.instance.generateStudentDay(_selectedDate);
                          await _loadData();
                        } catch (error) {
                          _showSnack('হিফজ পরিকল্পনা তৈরি করা যায়নি: $error');
                        }
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text('আজকের পরিকল্পনা', style: GoogleFonts.notoSansBengali()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F5132),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showStudentHifzSettings,
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text('রুটিন সেটিংস', style: GoogleFonts.notoSansBengali()),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addMemorizedPortion,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('মুখস্থ অংশ যোগ', style: GoogleFonts.notoSansBengali()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'আজকের সবক · সবকি · মনজিল',
            style: GoogleFonts.notoSansBengali(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(height: 8),
          if (log.hifzAssignments.isEmpty)
            _buildHifzEmptyCard('এই দিনের পরিকল্পনা এখনো তৈরি হয়নি।')
          else
            ...log.hifzAssignments.map(_buildHifzAssignmentCard),
          const SizedBox(height: 18),
          Text(
            'মুখস্থ অংশের তালিকা',
            style: GoogleFonts.notoSansBengali(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(height: 8),
          if (portions.isEmpty)
            _buildHifzEmptyCard('আগে মুখস্থ করা অংশ যোগ করলে সবকি ও মনজিল তৈরি হবে।')
          else
            ...portions.map(_buildMemorizedPortionCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHafezTab() {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    final settings = _plannerModel!.hafezSettings;
    final weakPortions = _plannerModel!.hafezWeakPortions;
    final cycleDays = settings.cycleDays;
    final dueWeakCount = weakPortions
        .where((portion) => PlannerService.isHafezWeakPortionDue(portion, _selectedDate))
        .length;
    final todayRanges = PlannerService.buildHafezDayPagePlan(settings);
    final todayPages = todayRanges.fold<int>(0, (total, range) => total + range.$2 - range.$1 + 1);
    final statusLabels = {
      'weak': 'দুর্বল',
      'reinforcement': 'অতিরিক্ত ঝালাই',
      'strengthened': 'সাম্প্রতিকভাবে মজবুত',
    };

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHorizontalDateStrip(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F5132),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'দৌর সংরক্ষণ',
                  style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${TriCalendarHelper.toBnNum(cycleDays)} দিনের নির্বাচিত চক্র · '
                  'আজকের লক্ষ্য ${TriCalendarHelper.toBnNum(todayPages)} পৃষ্ঠা · '
                  '${TriCalendarHelper.toBnNum(dueWeakCount)}টি দুর্বল রেঞ্জ নির্ধারিত',
                  style: GoogleFonts.notoSansBengali(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await PlannerService.instance.generateHafezDay(_selectedDate);
                          await _loadData();
                        } catch (error) {
                          _showSnack('দৌর পরিকল্পনা তৈরি করা যায়নি: $error');
                        }
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text('আজকের দৌর', style: GoogleFonts.notoSansBengali()),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: _showHafezSettings,
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text('সাইকেল সেটিংস', style: GoogleFonts.notoSansBengali()),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: _addHafezWeakPortion,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: Text('দুর্বল রেঞ্জ', style: GoogleFonts.notoSansBengali()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'আজকের দৌর ও অতিরিক্ত পুনরাবৃত্তি',
            style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F5132)),
          ),
          const SizedBox(height: 8),
          if (log.hafezAssignments.isEmpty)
            _buildHifzEmptyCard('এই দিনের পরিকল্পনা এখনো তৈরি হয়নি।')
          else
            ...log.hafezAssignments.map(_buildHafezAssignmentCard),
          const SizedBox(height: 18),
          Text(
            'দুর্বল অংশের তালিকা',
            style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F5132)),
          ),
          const SizedBox(height: 8),
          if (weakPortions.isEmpty)
            _buildHifzEmptyCard('দৌর থেকে অতিরিক্ত ঝালাই প্রয়োজন এমন রেঞ্জ এখানে যোগ করুন।')
          else
            ...weakPortions.map(
              (portion) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                elevation: 0,
                child: ListTile(
                  dense: true,
                  title: Text(_readingRangeLabel(portion.range), style: GoogleFonts.notoSansBengali(fontSize: 12)),
                  subtitle: Text(
                    '${statusLabels[portion.status] ?? portion.status}'
                    '${portion.nextReviewDate == null ? '' : ' · পরবর্তী: ${portion.nextReviewDate}'}',
                    style: GoogleFonts.notoSansBengali(fontSize: 11),
                  ),
                  onTap: () => widget.onOpenPage(portion.range.startPage),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHafezAssignmentCard(HafezAssignment assignment) {
    final isWeak = assignment.category == 'weak';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: assignment.status == 'completed' ? const Color(0xFF8DC9A4) : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWeak ? 'দুর্বল অংশ · অতিরিক্ত ঝালাই' : 'দৌর · পূর্ণ কুরআন চক্র',
              style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(_readingRangeLabel(assignment.range), style: GoogleFonts.notoSansBengali(fontSize: 12)),
            if (assignment.originalDateKey != null)
              Text(
                'মূল তারিখ ${assignment.originalDateKey}',
                style: GoogleFonts.notoSansBengali(fontSize: 10.5, color: Colors.grey[600]),
              ),
            if (assignment.assessment != null)
              Text(
                'মূল্যায়ন: ${_assessmentLabel(assignment.assessment!)}'
                '${assignment.repetitionCount == 0 ? '' : ' · ${TriCalendarHelper.toBnNum(assignment.repetitionCount)} বার'}',
                style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
              ),
            if (assignment.teacherFeedback.isNotEmpty)
              Text('নিজের নোট: ${assignment.teacherFeedback}', style: GoogleFonts.notoSansBengali(fontSize: 11)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _recordHafezAssessment(assignment),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text('মূল্যায়ন রেকর্ড', style: GoogleFonts.notoSansBengali()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHafezSettings() async {
    final current = _plannerModel!.hafezSettings;
    final cycleController = TextEditingController(text: current.cycleDays.toString());
    final pagesController = TextEditingController(text: current.daurPages.toString());
    final cursorController = TextEditingController(text: current.daurCursorPage.toString());
    var availableWeekdays = List<int>.from(current.availableWeekdays);
    var customRotationEnabled = current.customRotationEnabled;
    final customRanges = List<QuranRange>.from(current.customRotationRanges);
    final result = await showDialog<HafezSettings>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('দৌর সাইকেল সেটিংস', style: GoogleFonts.notoSansBengali()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _hifzNumberField(cycleController, 'সাইকেলের দিন (১–৩৬৫)'),
                _hifzNumberField(pagesController, 'দৈনিক দৌরের পৃষ্ঠা'),
                if (!customRotationEnabled)
                  _hifzNumberField(cursorController, 'বর্তমান দৌর শুরুর পৃষ্ঠা (১–৬১২)'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('নিজস্ব রেঞ্জের ঘূর্ণন', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                  subtitle: Text(
                    'নির্বাচিত রেঞ্জগুলো ক্রমানুসারে পুনরাবৃত্ত হবে।',
                    style: GoogleFonts.notoSansBengali(fontSize: 10),
                  ),
                  value: customRotationEnabled,
                  onChanged: (value) => setDialogState(() => customRotationEnabled = value),
                ),
                if (customRotationEnabled) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final range = await showQuranRangeSelector(context);
                        if (range == null) return;
                        setDialogState(() => customRanges.add(range));
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('ঘূর্ণনে রেঞ্জ যোগ করুন', style: GoogleFonts.notoSansBengali(fontSize: 11)),
                    ),
                  ),
                  ...customRanges.asMap().entries.map((entry) {
                    final index = entry.key;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${index + 1}. ${_readingRangeLabel(entry.value)}',
                        style: GoogleFonts.notoSansBengali(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'উপরে নিন',
                            icon: const Icon(Icons.arrow_upward, size: 16),
                            onPressed: index == 0
                                ? null
                                : () => setDialogState(() {
                                      final item = customRanges.removeAt(index);
                                      customRanges.insert(index - 1, item);
                                    }),
                          ),
                          IconButton(
                            tooltip: 'নিচে নিন',
                            icon: const Icon(Icons.arrow_downward, size: 16),
                            onPressed: index == customRanges.length - 1
                                ? null
                                : () => setDialogState(() {
                                      final item = customRanges.removeAt(index);
                                      customRanges.insert(index + 1, item);
                                    }),
                          ),
                          IconButton(
                            tooltip: 'রেঞ্জ সরান',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => setDialogState(() => customRanges.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                _buildWeekdaySelector(
                  title: 'দৌরের দিন (ফাঁকা রাখলে বিরতি)',
                  selectedDays: availableWeekdays,
                  onChanged: (days) => setDialogState(() => availableWeekdays = days),
                ),
                const SizedBox(height: 8),
                Text(
                  'এগুলো আপনার পছন্দের কাজের পরিমাণ; কোনো নির্দিষ্ট দৌরকে সবার জন্য সুপারিশ করা হচ্ছে না।',
                  style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final cycle = int.tryParse(cycleController.text);
                final pages = int.tryParse(pagesController.text);
                final cursor = int.tryParse(cursorController.text);
                if (cycle == null ||
                    pages == null ||
                    cycle < 1 ||
                    cycle > 365 ||
                    pages < 1 ||
                    pages > 612 ||
                    (!customRotationEnabled && (cursor == null || cursor < 1 || cursor > 612)) ||
                    (customRotationEnabled && customRanges.isEmpty)) {
                  _showSnack('সাইকেল, দৈনিক পৃষ্ঠা এবং রেঞ্জের মান যাচাই করুন।');
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  HafezSettings(
                    cycleDays: cycle,
                    daurPages: pages,
                    daurCursorPage: cursor ?? current.daurCursorPage,
                    availableWeekdays: availableWeekdays,
                    customRotationEnabled: customRotationEnabled,
                    customRotationRanges: customRanges,
                    customRotationCursor: current.customRotationCursor,
                  ),
                );
              },
              child: Text('সংরক্ষণ', style: GoogleFonts.notoSansBengali()),
            ),
          ],
        ),
      ),
    );
    cycleController.dispose();
    pagesController.dispose();
    cursorController.dispose();
    if (result == null || !mounted) return;
    try {
      await PlannerService.instance.saveHafezSettings(result);
      await _loadData();
    } catch (error) {
      _showSnack('দৌর সেটিংস সংরক্ষণ করা যায়নি: $error');
    }
  }

  Future<void> _addHafezWeakPortion() async {
    final range = await showQuranRangeSelector(context);
    if (range == null || !mounted) return;
    final nextReview = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'অতিরিক্ত পুনরাবৃত্তির তারিখ',
    );
    if (nextReview == null || !mounted) return;
    try {
      await PlannerService.instance.addHafezWeakPortion(
        range: range,
        addedDate: _selectedDate,
        nextReviewDate: nextReview,
      );
      await _loadData();
    } catch (error) {
      _showSnack('দুর্বল রেঞ্জ সংরক্ষণ করা যায়নি: $error');
    }
  }

  Future<void> _recordHafezAssessment(HafezAssignment assignment) async {
    const mistakeLabels = {
      'missedAyah': 'আয়াত বাদ',
      'wordSubstitution': 'শব্দ পরিবর্তন',
      'hesitation': 'বিরতি',
      'sequenceConfusion': 'আয়াতের ক্রম',
      'tajweed': 'তাজবিদ সংশোধন',
    };
    final repetitions = TextEditingController(text: assignment.repetitionCount.toString());
    final feedback = TextEditingController(text: assignment.teacherFeedback);
    var assessment = assignment.assessment ?? 'perfect';
    var markCompleted = assignment.status == 'completed';
    final mistakes = <String>{...assignment.mistakes};
    final result = await showDialog<(String, List<String>, int, String, bool)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('দৌর মূল্যায়ন', style: GoogleFonts.notoSansBengali()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: assessment,
                  decoration: const InputDecoration(labelText: 'আবৃত্তির অবস্থা'),
                  items: const [
                    DropdownMenuItem(value: 'perfect', child: Text('নির্ভুল')),
                    DropdownMenuItem(value: 'minor', child: Text('সামান্য বিরতি')),
                    DropdownMenuItem(value: 'multiple', child: Text('একাধিক ভুল')),
                    DropdownMenuItem(value: 'assistance', child: Text('সহায়তা প্রয়োজন')),
                    DropdownMenuItem(value: 'repeat', child: Text('পুনরায় পড়তে হবে')),
                  ],
                  onChanged: (value) => setDialogState(() => assessment = value ?? assessment),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: mistakeLabels.entries.map((entry) {
                    return FilterChip(
                      label: Text(entry.value, style: GoogleFonts.notoSansBengali(fontSize: 10)),
                      selected: mistakes.contains(entry.key),
                      onSelected: (selected) => setDialogState(
                        () => selected ? mistakes.add(entry.key) : mistakes.remove(entry.key),
                      ),
                    );
                  }).toList(),
                ),
                _hifzNumberField(repetitions, 'পুনরাবৃত্তির সংখ্যা'),
                const SizedBox(height: 8),
                TextField(
                  controller: feedback,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'নিজের নোট (ঐচ্ছিক)',
                    border: OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: markCompleted,
                  onChanged: (value) => setDialogState(() => markCompleted = value ?? false),
                  title: Text('এই রেঞ্জটি সম্পন্ন', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final count = int.tryParse(repetitions.text) ?? -1;
                if (count < 0 || count > 10000) {
                  _showSnack('পুনরাবৃত্তি ০–১০০০০ এর মধ্যে দিন।');
                  return;
                }
                Navigator.pop(dialogContext, (assessment, mistakes.toList(), count, feedback.text, markCompleted));
              },
              child: Text('সংরক্ষণ', style: GoogleFonts.notoSansBengali()),
            ),
          ],
        ),
      ),
    );
    repetitions.dispose();
    feedback.dispose();
    if (result == null || !mounted) return;
    try {
      await PlannerService.instance.recordHafezAssessment(
        dateKey: TriCalendarHelper.formatDateKey(_selectedDate),
        assignmentId: assignment.id,
        assessment: result.$1,
        mistakes: result.$2,
        repetitionCount: result.$3,
        teacherFeedback: result.$4,
        markCompleted: result.$5,
      );
      await _loadData();
      _showSnack('মূল্যায়ন সংরক্ষিত হয়েছে। এটি ব্যবহারকারীর রেকর্ড, স্বয়ংক্রিয় যাচাই নয়।');
    } catch (error) {
      _showSnack('মূল্যায়ন সংরক্ষণ করা যায়নি: $error');
    }
  }

  Widget _buildHifzEmptyCard(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(message, style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[700])),
      );

  Widget _buildHifzAssignmentCard(HifzAssignment assignment) {
    final category = switch (assignment.category) {
      'sabaq' => 'সবক · নতুন মুখস্থ',
      'sabqi' => 'সবকি · সাম্প্রতিক পুনরাবৃত্তি',
      'manzil' => 'মনজিল · পুরোনো পুনরাবৃত্তি',
      _ => assignment.category,
    };
    final statusLabel = assignment.status == 'completed'
        ? 'সম্পন্ন'
        : assignment.status == 'partial'
            ? 'আংশিক'
            : 'বাকি';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: assignment.status == 'completed' ? const Color(0xFF8DC9A4) : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(category, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                ),
                Text(statusLabel, style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 5),
            Text(_readingRangeLabel(assignment.range), style: GoogleFonts.notoSansBengali(fontSize: 12)),
            if (assignment.originalDateKey != null)
              Text(
                'মূল তারিখ ${assignment.originalDateKey}',
                style: GoogleFonts.notoSansBengali(fontSize: 10.5, color: Colors.grey[600]),
              ),
            if (assignment.assessment != null) ...[
              const SizedBox(height: 4),
              Text(
                'মূল্যায়ন: ${_assessmentLabel(assignment.assessment!)}'
                '${assignment.repetitionCount > 0 ? ' · পুনরাবৃত্তি ${TriCalendarHelper.toBnNum(assignment.repetitionCount)} বার' : ''}',
                style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
            if (assignment.actualRange != null)
              Text(
                'বাস্তবে পড়া: ${_readingRangeLabel(assignment.actualRange!)}',
                style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
              ),
            if (assignment.teacherFeedback.isNotEmpty)
              Text('নিজের নোট: ${assignment.teacherFeedback}', style: GoogleFonts.notoSansBengali(fontSize: 11)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (assignment.status == 'pending')
                  IconButton(
                    tooltip: 'পরিকল্পিত রেঞ্জ সম্পাদনা',
                    onPressed: () => _editStudentAssignmentRange(assignment),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                TextButton.icon(
                  onPressed: () => _recordHifzAssessment(assignment),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: Text(
                    assignment.assessment == null ? 'তিলাওয়াতের মূল্যায়ন' : 'মূল্যায়ন সম্পাদনা',
                    style: GoogleFonts.notoSansBengali(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _assessmentLabel(String assessment) => switch (assessment) {
        'perfect' => 'নির্ভুল',
        'minor' => 'সামান্য বিরতি',
        'multiple' => 'একাধিক ভুল',
        'assistance' => 'সহায়তা প্রয়োজন',
        'repeat' => 'আবার পড়তে হবে',
        _ => assessment,
      };

  Future<void> _editStudentAssignmentRange(HifzAssignment assignment) async {
    final selected = await showQuranRangeSelector(context);
    if (selected == null || !mounted) return;
    try {
      await PlannerService.instance.updateStudentAssignmentRange(
        dateKey: TriCalendarHelper.formatDateKey(_selectedDate),
        assignmentId: assignment.id,
        range: selected,
      );
      await _loadData();
    } catch (error) {
      _showSnack('পরিকল্পিত রেঞ্জ সম্পাদনা করা যায়নি: $error');
    }
  }

  Widget _buildMemorizedPortionCard(MemorizedPortion portion) {
    final status = switch (portion.status) {
      'learning' => 'শিখছেন',
      'recent' => 'সাম্প্রতিক · সবকি',
      'established' => 'প্রতিষ্ঠিত · মনজিল',
      'reinforcement' => 'পুনর্বলন প্রয়োজন',
      _ => portion.status,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      child: ListTile(
        dense: true,
        title: Text(_readingRangeLabel(portion.range), style: GoogleFonts.notoSansBengali(fontSize: 12)),
        subtitle: Text(status, style: GoogleFonts.notoSansBengali(fontSize: 11)),
        trailing: PopupMenuButton<String>(
          tooltip: 'মুখস্থের অবস্থা পরিবর্তন',
          onSelected: (value) async {
            try {
              await PlannerService.instance.updateMemorizedPortionStatus(portion.id, value);
              await _loadData();
            } catch (error) {
              _showSnack('অবস্থা সংরক্ষণ করা যায়নি: $error');
            }
          },
          itemBuilder: (context) => [
            _statusMenuItem('learning', 'শিখছেন'),
            _statusMenuItem('recent', 'সাম্প্রতিক · সবকি'),
            _statusMenuItem('established', 'প্রতিষ্ঠিত · মনজিল'),
            _statusMenuItem('reinforcement', 'পুনর্বলন প্রয়োজন'),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _statusMenuItem(String value, String label) => PopupMenuItem(
        value: value,
        child: Text(label, style: GoogleFonts.notoSansBengali(fontSize: 12)),
      );

  Future<void> _addMemorizedPortion() async {
    final range = await showQuranRangeSelector(context);
    if (range == null || !mounted) return;
    final status = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('মুখস্থ অংশের অবস্থা', style: GoogleFonts.notoSansBengali()),
        children: [
          for (final item in const [
            ('established', 'প্রতিষ্ঠিত · মনজিলের জন্য প্রস্তুত'),
            ('recent', 'সাম্প্রতিক · সবকি'),
            ('learning', 'শিখছেন'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item.$1),
              child: Text(item.$2, style: GoogleFonts.notoSansBengali()),
            ),
        ],
      ),
    );
    if (status == null || !mounted) return;
    try {
      await PlannerService.instance.addMemorizedPortion(
        range: range,
        status: status,
        date: _selectedDate,
      );
      await _loadData();
    } catch (error) {
      _showSnack('মুখস্থ অংশ যোগ করা যায়নি: $error');
    }
  }

  Future<void> _showStudentHifzSettings() async {
    final current = _plannerModel!.studentHifzSettings;
    final startController = TextEditingController(text: current.sabaqStartPage.toString());
    final sabaqController = TextEditingController(text: current.sabaqPages.toString());
    final lessonsController = TextEditingController(text: current.sabqiLessonCount.toString());
    final sabqiPagesController = TextEditingController(text: current.sabqiPageCount.toString());
    final manzilController = TextEditingController(text: current.manzilPages.toString());
    final cursorController = TextEditingController(text: current.manzilCursorPage.toString());
    var method = current.revisionMethod == 'teacher' ? 'traditional' : current.revisionMethod;
    var sabqiRule = current.sabqiRule;
    var sabaqReminderEnabled = current.sabaqReminderEnabled;
    var sabaqReminderTime = current.sabaqReminderTime;
    var sabqiReminderEnabled = current.sabqiReminderEnabled;
    var sabqiReminderTime = current.sabqiReminderTime;
    var manzilReminderEnabled = current.manzilReminderEnabled;
    var manzilReminderTime = current.manzilReminderTime;
    var sabaqWeekdays = List<int>.from(current.sabaqWeekdays);
    var sabqiWeekdays = List<int>.from(current.sabqiWeekdays);
    var manzilWeekdays = List<int>.from(current.manzilWeekdays);
    final result = await showDialog<HifzSettings>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('হিফজ রুটিন সেটিংস', style: GoogleFonts.notoSansBengali()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _hifzNumberField(startController, 'পরবর্তী সবকের শুরুর পৃষ্ঠা (১–৬১৩; ৬১৩ মানে সম্পন্ন)'),
                _hifzNumberField(sabaqController, 'প্রতিদিনের সবক (পৃষ্ঠা)'),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'পুনরাবৃত্তির পদ্ধতি'),
                  items: const [
                    DropdownMenuItem(value: 'traditional', child: Text('ঐতিহ্যবাহী')),
                    DropdownMenuItem(value: 'custom', child: Text('নিজস্ব পরিকল্পনা')),
                  ],
                  onChanged: (value) => setDialogState(() => method = value ?? method),
                ),
                DropdownButtonFormField<String>(
                  value: sabqiRule,
                  decoration: const InputDecoration(labelText: 'সবকি নির্ধারণ'),
                  items: const [
                    DropdownMenuItem(value: 'lessons', child: Text('শেষ Nটি মুখস্থ অংশ')),
                    DropdownMenuItem(value: 'pages', child: Text('সর্বোচ্চ পৃষ্ঠা')),
                  ],
                  onChanged: (value) => setDialogState(() => sabqiRule = value ?? sabqiRule),
                ),
                if (sabqiRule == 'lessons') _hifzNumberField(lessonsController, 'সবকি অংশের সংখ্যা'),
                if (sabqiRule == 'pages') _hifzNumberField(sabqiPagesController, 'সবকির পৃষ্ঠা সংখ্যা'),
                _hifzNumberField(manzilController, 'দৈনিক মনজিলের পৃষ্ঠা'),
                _hifzNumberField(cursorController, 'মনজিল ঘূর্ণনের বর্তমান পৃষ্ঠা'),
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('কাজভিত্তিক রিমাইন্ডার', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600)),
                ),
                _buildHifzReminderSetting(
                  title: 'সবক · নতুন মুখস্থ',
                  enabled: sabaqReminderEnabled,
                  time: sabaqReminderTime,
                  onEnabledChanged: (value) => setDialogState(() => sabaqReminderEnabled = value),
                  onTimeChanged: (value) => setDialogState(() => sabaqReminderTime = value),
                ),
                _buildHifzReminderSetting(
                  title: 'সবকি · সাম্প্রতিক পুনরাবৃত্তি',
                  enabled: sabqiReminderEnabled,
                  time: sabqiReminderTime,
                  onEnabledChanged: (value) => setDialogState(() => sabqiReminderEnabled = value),
                  onTimeChanged: (value) => setDialogState(() => sabqiReminderTime = value),
                ),
                _buildHifzReminderSetting(
                  title: 'মনজিল · পুরোনো পুনরাবৃত্তি',
                  enabled: manzilReminderEnabled,
                  time: manzilReminderTime,
                  onEnabledChanged: (value) => setDialogState(() => manzilReminderEnabled = value),
                  onTimeChanged: (value) => setDialogState(() => manzilReminderTime = value),
                ),
                _buildWeekdaySelector(
                  title: 'সবকের দিন',
                  selectedDays: sabaqWeekdays,
                  onChanged: (days) => setDialogState(() => sabaqWeekdays = days),
                ),
                _buildWeekdaySelector(
                  title: 'সবকির দিন',
                  selectedDays: sabqiWeekdays,
                  onChanged: (days) => setDialogState(() => sabqiWeekdays = days),
                ),
                _buildWeekdaySelector(
                  title: 'মনজিলের দিন',
                  selectedDays: manzilWeekdays,
                  onChanged: (days) => setDialogState(() => manzilWeekdays = days),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
            ),
            FilledButton(
              onPressed: () {
                final start = int.tryParse(startController.text);
                final sabaq = int.tryParse(sabaqController.text);
                final lessons = int.tryParse(lessonsController.text);
                final sabqiPages = int.tryParse(sabqiPagesController.text);
                final manzil = int.tryParse(manzilController.text);
                final cursor = int.tryParse(cursorController.text);
                if (start == null ||
                    sabaq == null ||
                    lessons == null ||
                    sabqiPages == null ||
                    manzil == null ||
                    cursor == null ||
                    start < 1 ||
                    start > 613 ||
                    sabaq < 1 ||
                    sabaq > 612 ||
                    lessons < 1 ||
                    lessons > 100 ||
                    sabqiPages < 1 ||
                    sabqiPages > 612 ||
                    manzil < 1 ||
                    manzil > 612 ||
                    cursor < 1 ||
                    cursor > 612) {
                  _showSnack('প্রতিটি মান নির্ধারিত সীমার মধ্যে দিন।');
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  HifzSettings(
                    sabaqStartPage: start,
                    sabaqPages: sabaq,
                    revisionMethod: method,
                    sabqiRule: sabqiRule,
                    sabqiLessonCount: lessons,
                    sabqiPageCount: sabqiPages,
                    manzilPages: manzil,
                    manzilCursorPage: cursor,
                    sabaqReminderEnabled: sabaqReminderEnabled,
                    sabaqReminderTime: sabaqReminderTime,
                    sabqiReminderEnabled: sabqiReminderEnabled,
                    sabqiReminderTime: sabqiReminderTime,
                    manzilReminderEnabled: manzilReminderEnabled,
                    manzilReminderTime: manzilReminderTime,
                    sabaqWeekdays: sabaqWeekdays,
                    sabqiWeekdays: sabqiWeekdays,
                    manzilWeekdays: manzilWeekdays,
                  ),
                );
              },
              child: Text('সংরক্ষণ', style: GoogleFonts.notoSansBengali()),
            ),
          ],
        ),
      ),
    );
    startController.dispose();
    sabaqController.dispose();
    lessonsController.dispose();
    sabqiPagesController.dispose();
    manzilController.dispose();
    cursorController.dispose();
    if (result == null || !mounted) return;
    var settingsSaved = false;
    try {
      await PlannerService.instance.saveStudentHifzSettings(result);
      settingsSaved = true;
      final remindersScheduled = await PlannerService.instance.restoreStudentHifzReminders();
      await _loadData();
      if (!remindersScheduled) {
        _showSnack('রুটিন সংরক্ষিত হয়েছে, তবে নোটিফিকেশন অনুমতি না থাকায় রিমাইন্ডার চালু হয়নি।');
      }
    } catch (error) {
      if (settingsSaved) {
        await _loadData();
        _showSnack('রুটিন সংরক্ষিত হয়েছে, তবে রিমাইন্ডার সেট করা যায়নি: $error');
      } else {
        _showSnack('হিফজ রুটিন সংরক্ষণ করা যায়নি: $error');
      }
    }
  }

  Widget _buildWeekdaySelector({
    required String title,
    required List<int> selectedDays,
    required ValueChanged<List<int>> onChanged,
  }) {
    const labels = {
      1: 'সোম',
      2: 'মঙ্গল',
      3: 'বুধ',
      4: 'বৃহস্পতি',
      5: 'শুক্র',
      6: 'শনি',
      7: 'রবি',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.notoSansBengali(fontSize: 12)),
          Wrap(
            spacing: 4,
            children: labels.entries.map((entry) {
              return FilterChip(
                label: Text(entry.value, style: GoogleFonts.notoSansBengali(fontSize: 10)),
                selected: selectedDays.contains(entry.key),
                onSelected: (selected) {
                  final updated = List<int>.from(selectedDays);
                  if (selected) {
                    updated.add(entry.key);
                  } else {
                    updated.remove(entry.key);
                  }
                  updated.sort();
                  onChanged(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHifzReminderSetting({
    required String title,
    required bool enabled,
    required String time,
    required ValueChanged<bool> onEnabledChanged,
    required ValueChanged<String> onTimeChanged,
  }) {
    final parts = time.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    final initialTime = hour != null &&
            minute != null &&
            hour >= 0 &&
            hour <= 23 &&
            minute >= 0 &&
            minute <= 59
        ? TimeOfDay(hour: hour, minute: minute)
        : const TimeOfDay(hour: 6, minute: 0);
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: const Color(0xFF0F5132),
          title: Text(title, style: GoogleFonts.notoSansBengali(fontSize: 12)),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        if (enabled)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.access_time, size: 16),
              label: Text('$time · সময় নির্বাচন', style: GoogleFonts.notoSansBengali(fontSize: 11)),
              onPressed: () async {
                final selected = await showTimePicker(context: context, initialTime: initialTime);
                if (selected == null) return;
                onTimeChanged(
                  '${selected.hour.toString().padLeft(2, '0')}:'
                  '${selected.minute.toString().padLeft(2, '0')}',
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _hifzNumberField(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Future<void> _recordHifzAssessment(HifzAssignment assignment) async {
    const mistakeLabels = {
      'missedAyah': 'আয়াত বাদ',
      'wordSubstitution': 'শব্দ পরিবর্তন',
      'hesitation': 'বিরতি',
      'sequenceConfusion': 'আয়াতের ক্রম',
      'tajweed': 'তাজবিদ সংশোধন',
    };
    final repetitions = TextEditingController(text: assignment.repetitionCount.toString());
    final feedback = TextEditingController(text: assignment.teacherFeedback);
    var assessment = assignment.assessment ?? 'perfect';
    var markCompleted = assignment.status == 'completed';
    QuranRange? actualRange = assignment.actualRange;
    final mistakes = <String>{...assignment.mistakes};
    final result = await showDialog<(String, List<String>, int, String, bool)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('তিলাওয়াতের মূল্যায়ন', style: GoogleFonts.notoSansBengali()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: assessment,
                  decoration: const InputDecoration(labelText: 'আবৃত্তির অবস্থা'),
                  items: const [
                    DropdownMenuItem(value: 'perfect', child: Text('নির্ভুল / উল্লেখযোগ্য ভুল নেই')),
                    DropdownMenuItem(value: 'minor', child: Text('সামান্য বিরতি')),
                    DropdownMenuItem(value: 'multiple', child: Text('একাধিক ভুল')),
                    DropdownMenuItem(value: 'assistance', child: Text('সহায়তা প্রয়োজন')),
                    DropdownMenuItem(value: 'repeat', child: Text('পুনরায় পড়তে হবে')),
                  ],
                  onChanged: (value) => setDialogState(() => assessment = value ?? assessment),
                ),
                const SizedBox(height: 12),
                Text('ভুলের ধরন (ঐচ্ছিক)', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 4,
                  children: mistakeLabels.entries.map((entry) {
                    return FilterChip(
                      label: Text(entry.value, style: GoogleFonts.notoSansBengali(fontSize: 11)),
                      selected: mistakes.contains(entry.key),
                      onSelected: (selected) => setDialogState(
                        () => selected ? mistakes.add(entry.key) : mistakes.remove(entry.key),
                      ),
                    );
                  }).toList(),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showQuranRangeSelector(context);
                    if (selected != null) setDialogState(() => actualRange = selected);
                  },
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(
                    actualRange == null
                        ? 'বাস্তবে পড়া রেঞ্জ (ঐচ্ছিক)'
                        : _readingRangeLabel(actualRange!),
                    style: GoogleFonts.notoSansBengali(fontSize: 11),
                  ),
                ),
                _hifzNumberField(repetitions, 'পুনরাবৃত্তির সংখ্যা'),
                const SizedBox(height: 8),
                TextField(
                  controller: feedback,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'নিজের নোট (ঐচ্ছিক)',
                    border: OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: markCompleted,
                  onChanged: (value) => setDialogState(() => markCompleted = value ?? false),
                  title: Text(
                    assignment.category == 'sabaq' ? 'আমি এই সবক মুখস্থ করেছি' : 'এই পুনরাবৃত্তি সম্পন্ন',
                    style: GoogleFonts.notoSansBengali(fontSize: 12),
                  ),
                  subtitle: assignment.category == 'sabaq'
                      ? Text('এটি নিশ্চিত করলে অংশটি সাম্প্রতিক সবকিতে যাবে।', style: GoogleFonts.notoSansBengali(fontSize: 10))
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final count = int.tryParse(repetitions.text) ?? -1;
                if (count < 0 || count > 10000) {
                  _showSnack('পুনরাবৃত্তির সংখ্যা ০–১০০০০ এর মধ্যে দিন।');
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  (assessment, mistakes.toList(), count, feedback.text, markCompleted),
                );
              },
              child: Text('সংরক্ষণ', style: GoogleFonts.notoSansBengali()),
            ),
          ],
        ),
      ),
    );
    repetitions.dispose();
    feedback.dispose();
    if (result == null || !mounted) return;
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    try {
      await PlannerService.instance.recordHifzAssessment(
        dateKey: dateKey,
        assignmentId: assignment.id,
        assessment: result.$1,
        mistakes: result.$2,
        repetitionCount: result.$3,
        teacherFeedback: result.$4,
        markCompleted: result.$5,
        actualRange: actualRange,
      );
      await _loadData();
      _showSnack('মূল্যায়ন সংরক্ষিত হয়েছে। এটি ব্যবহারকারীর রেকর্ড, স্বয়ংক্রিয় যাচাই নয়।');
    } catch (error) {
      _showSnack('মূল্যায়ন সংরক্ষণ করা যায়নি: $error');
    }
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: const Color(0xFF0F5132)),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDestructive ? Colors.redAccent.withOpacity(0.5) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red[800] : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalDateStrip() {
    final now = DateTime.now();
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final dates = List.generate(11, (i) => selectedDay.add(Duration(days: i - 5)));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final d = dates[index];
          final isSelected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
          final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
          final dKey = TriCalendarHelper.formatDateKey(d);
          final log = _plannerModel?.logs[dKey];
          final isCompleted = log?.status == 'completed';

          const dayNames = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
          final dayName = dayNames[d.weekday - 1];

          return GestureDetector(
            onTap: () => _changeSelectedDate(d),
            child: Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0F5132)
                    : isToday
                        ? const Color(0xFFE8F5E9)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F5132)
                      : isToday
                          ? const Color(0xFF0F5132)
                          : Colors.grey[300]!,
                  width: isSelected || isToday ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0F5132).withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    TriCalendarHelper.toBnNum(d.day),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 11,
                    color: isCompleted
                        ? (isSelected ? const Color(0xFFFDE68A) : const Color(0xFF0F5132))
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSevenDayStreak() {
    final now = DateTime.now();
    final past7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    int streakCount = 0;

    for (final d in past7Days) {
      final key = TriCalendarHelper.formatDateKey(d);
      if (_plannerModel?.logs[key]?.status == 'completed') {
        streakCount++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'গত ৭ দিনে সম্পন্ন দিন',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${TriCalendarHelper.toBnNum(streakCount)}/৭ দিন',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F5132),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: past7Days.map((d) {
              final key = TriCalendarHelper.formatDateKey(d);
              final isDone = _plannerModel?.logs[key]?.status == 'completed';
              const dayNames = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? const Color(0xFF0F5132) : Colors.grey[200],
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.close,
                      color: isDone ? Colors.white : Colors.grey[400],
                      size: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNames[d.weekday - 1],
                    style: GoogleFonts.notoSansBengali(fontSize: 9.5, color: Colors.grey[600]),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: ROADMAP & PLANNER (রোডম্যাপ ও প্ল্যান)
  // ----------------------------------------------------
  Widget _buildReaderSessionsEditor() {
    final sessions = _plannerModel!.readerSessions;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'পছন্দের রিডিং সেশন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F5132),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _editReadingSession(),
                icon: const Icon(Icons.add, size: 17),
                label: Text('যোগ', style: GoogleFonts.notoSansBengali(fontSize: 11)),
              ),
            ],
          ),
          Text(
            'দৈনিক পড়া বাছাই করা সময়গুলোতে সমান ভাগে ভাগ হবে। সময়গুলো স্থানীয় রুটিনের লেবেল; নোটিফিকেশন নয়।',
            style: GoogleFonts.notoSansBengali(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          ...sessions.map(
            (session) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule, color: Color(0xFF0F5132), size: 20),
              title: Text(session.title, style: GoogleFonts.notoSansBengali(fontSize: 12)),
              subtitle: Text(session.time, style: GoogleFonts.notoSansBengali(fontSize: 10)),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'সম্পাদনা',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _editReadingSession(session),
                  ),
                  IconButton(
                    tooltip: 'মুছুন',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: sessions.length == 1 ? null : () => _deleteReadingSession(session),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapTab(String mode) {
    if (mode == 'student') return _buildStudentHifzRoadmap();
    if (mode == 'hafiz') return _buildHafezRoadmap();

    final targetDaysInput = int.tryParse(_targetDaysController.text.trim()) ?? _cycleTargetDays;
    final requestedPages = (int.tryParse(_pagesPerDayController.text.trim()) ?? _pagesPerDay)
        .clamp(1, PlannerService.totalQuranPages)
        .toInt();
    final requestedStartPage = mode == 'general'
        ? (int.tryParse(_startPageController.text.trim()) ?? _planStartPage)
            .clamp(1, PlannerService.totalQuranPages)
            .toInt()
        : ((_cycleStartPara - 1) * PlannerService.pagesPerPara) + 1;
    final remainingPages = PlannerService.totalQuranPages - requestedStartPage + 1;
    final validDays = mode == 'hafiz'
        ? targetDaysInput.clamp(1, 30).toInt()
        : _roadmapGoalMode == 'pages'
            ? (remainingPages / requestedPages).ceil()
            : targetDaysInput.clamp(1, mode == 'general' ? remainingPages : PlannerService.totalQuranPages).toInt();
    final dynamicDailyPace = _roadmapGoalMode == 'pages' && mode != 'hafiz'
        ? requestedPages
        : (remainingPages / validDays).ceil();
    final estCompletionDate = _planStartDate.add(Duration(days: validDays - 1));
    final previewStartPage = requestedStartPage;
    final previewEndPage = mode == 'general'
        ? (previewStartPage + dynamicDailyPace - 1).clamp(previewStartPage, PlannerService.totalQuranPages).toInt()
        : ((previewStartPage + dynamicDailyPace - 2) % PlannerService.totalQuranPages) + 1;
    final (hafizStartPara, hafizEndPara) = PlannerService.hafizParaRangeForDay(
      dayIndex: 0,
      targetDays: validDays,
      startPara: _cycleStartPara,
    );
    final previewRange = mode == 'hafiz'
        ? hafizEndPara < hafizStartPara
            ? 'পারা ${TriCalendarHelper.toBnNum(hafizStartPara)}-৩০ এবং ১-${TriCalendarHelper.toBnNum(hafizEndPara)}'
            : 'পারা ${TriCalendarHelper.toBnNum(hafizStartPara)}-${TriCalendarHelper.toBnNum(hafizEndPara)}'
        : mode != 'general' && previewEndPage < previewStartPage
            ? 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(previewStartPage)}-৬১২ এবং ১-${TriCalendarHelper.toBnNum(previewEndPage)}'
            : 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(previewStartPage)}-${TriCalendarHelper.toBnNum(previewEndPage)}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == 'general'
                      ? 'নতুন খতম পরিকল্পনা নির্ধারণ করুন'
                      : 'দাওর ও রিভিশন সাইকেল নির্ধারণ করুন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F5132),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'লক্ষ্য বেছে নিন; প্রতিদিনের নির্দিষ্ট কাজ ও তারিখের তালিকা নিচে তৈরি হবে।',
                  style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                if (mode != 'hafiz') ...[
                  Text('লক্ষ্য নির্ধারণের পদ্ধতি:', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('দিনে খতম', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                        selected: _roadmapGoalMode == 'days',
                        onSelected: (_) => setState(() => _roadmapGoalMode = 'days'),
                      ),
                      ChoiceChip(
                        label: Text('দৈনিক পৃষ্ঠা', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                        selected: _roadmapGoalMode == 'pages',
                        onSelected: (_) => setState(() => _roadmapGoalMode = 'pages'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (_roadmapGoalMode == 'pages' && mode != 'hafiz') ...[
                  Text('প্রতিদিন কত পৃষ্ঠা পড়বেন?', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _pagesPerDayController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      suffixText: 'পৃষ্ঠা/দিন',
                      hintText: '১-৬১২',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() => _pagesPerDay = parsed.clamp(1, PlannerService.totalQuranPages).toInt());
                      }
                    },
                  ),
                ] else ...[
                  Text(
                    mode == 'hafiz' ? 'দাওর সাইকেলের দৈর্ঘ্য:' : 'কত দিনে খতম করবেন?',
                    style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        _buildStepperButton(
                          icon: Icons.remove,
                          onPressed: () => _setTargetDays(_cycleTargetDays - 1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _targetDaysController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'দিন সংখ্যা'),
                            style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F5132)),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => _cycleTargetDays = parsed
                                  .clamp(
                                    1,
                                    mode == 'hafiz'
                                        ? 30
                                        : mode == 'general'
                                            ? remainingPages
                                            : PlannerService.totalQuranPages,
                                  )
                                  .toInt());
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStepperButton(
                          icon: Icons.add,
                          onPressed: () => _setTargetDays(_cycleTargetDays + 1),
                        ),
                        const SizedBox(width: 8),
                        Text('দিন', style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (mode == 'hafiz' ? [7, 15, 30] : [3, 5, 7, 10, 15, 20, 30, 60, 90]).map((days) {
                      final selected = _cycleTargetDays == days;
                      return ChoiceChip(
                        label: Text('${TriCalendarHelper.toBnNum(days)} দিন', style: GoogleFonts.notoSansBengali(fontSize: 11)),
                        selected: selected,
                        onSelected: (_) => _setTargetDays(days),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),

                if (mode == 'general') ...[
                  _buildReaderSessionsEditor(),
                  const SizedBox(height: 14),
                ],

                // Start point & Start date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mode == 'general') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'শুরুর পৃষ্ঠা (১–৬১২):',
                                    style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _useLastReadPage,
                                  child: Text('শেষ পড়া', style: GoogleFonts.notoSansBengali(fontSize: 11)),
                                ),
                              ],
                            ),
                            TextField(
                              controller: _startPageController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (value) {
                                final page = int.tryParse(value);
                                if (page != null && page >= 1 && page <= PlannerService.totalQuranPages) {
                                  setState(() {
                                    _planStartPage = page;
                                    final maxDays = PlannerService.totalQuranPages - page + 1;
                                    if (_roadmapGoalMode == 'days' && _cycleTargetDays > maxDays) {
                                      _cycleTargetDays = maxDays;
                                      _targetDaysController.text = maxDays.toString();
                                    }
                                  });
                                }
                              },
                            ),
                          ] else ...[
                            Text(
                              'শুরুর পারা:',
                              style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<int>(
                              value: _cycleStartPara,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: List.generate(30, (i) => i + 1).map((p) {
                                return DropdownMenuItem<int>(
                                  value: p,
                                  child: Text('পারা ${TriCalendarHelper.toBnNum(p)}', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _cycleStartPara = val);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'শুরুর তারিখ:',
                            style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _planStartDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (d != null) setState(() => _planStartDate = d);
                            },
                            child: Text(
                              '${TriCalendarHelper.toBnNum(_planStartDate.day)}/${TriCalendarHelper.toBnNum(_planStartDate.month)}/${TriCalendarHelper.toBnNum(_planStartDate.year)}',
                              style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dynamic Live Roadmap Preview Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F5132).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calculate_rounded, color: Color(0xFF0F5132), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'লাইভ রোডম্যাপ ক্যালকুলেটর:',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F5132),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${mode == 'hafiz' ? 'প্রথম দিনের দাওর' : 'প্রথম দিনের লক্ষ্য'}: $previewRange',
                        style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[800]),
                      ),
                      Text(
                        mode == 'hafiz'
                            ? 'দাওর সাইকেল: ${TriCalendarHelper.toBnNum(validDays)} দিন'
                            : 'লক্ষ্য: ${TriCalendarHelper.toBnNum(dynamicDailyPace)} পৃষ্ঠা/দিন · ${TriCalendarHelper.toBnNum(validDays)} দিন',
                        style: GoogleFonts.notoSansBengali(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F5132)),
                      ),
                      Text(
                        'সম্ভাব্য সমাপ্তির তারিখ: ${TriCalendarHelper.toBnNum(estCompletionDate.day)} ${TriCalendarHelper.getBengaliDate(estCompletionDate).monthName} ${TriCalendarHelper.toBnNum(estCompletionDate.year)}',
                        style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      'রোডম্যাপ তৈরি সম্পন্ন করুন',
                      style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _generateCycle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_cycleSummary != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F5132).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF0F5132)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _cycleSummary!,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12.5,
                        color: const Color(0xFF0F5132),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildGeneratedRoadmap(mode),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'নিয়মিত তিলাওয়াতের রুটিন পরামর্শ:',
                  style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F5132)),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('১. প্রতিদিন নির্দিষ্ট সময়ে (যেমন: ফজরের পর) তিলাওয়াত সম্পন্ন করার চেষ্টা করুন।'),
                _buildBulletPoint('২. এক বসায় সম্ভব না হলে ৫ ওয়াক্ত নামাজের পর ৪ পৃষ্ঠা করে পড়লে দিনে ১ পারা শেষ হয়।'),
                _buildBulletPoint('৩. হাফেজ ভাইদের জন্য প্রতিদিনের সবক ও সবকি তাজা রাখা দাওরের পূর্বশর্ত।'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHifzRoadmap() {
    final portions = _plannerModel!.memorizedPortions;
    final weeklyStats = PlannerService.calculateHifzWeeklyStats(
      _plannerModel!,
      weekEnding: DateTime.now(),
    );
    final recentLogs = _plannerModel!.logs.entries
        .where((entry) => entry.value.hifzAssignments.isNotEmpty)
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final counts = {
      'learning': portions.where((portion) => portion.status == 'learning').length,
      'recent': portions.where((portion) => portion.status == 'recent').length,
      'established': portions.where((portion) => portion.status == 'established').length,
      'reinforcement': portions.where((portion) => portion.status == 'reinforcement').length,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'হিফজ অগ্রগতি ও ইতিহাস',
            style: GoogleFonts.notoSansBengali(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'মুখস্থের অবস্থা কেবল আপনার স্পষ্ট আপডেটে বদলায়; সময় পার হওয়ায় কোনো অংশ স্বয়ংক্রিয়ভাবে প্রতিষ্ঠিত হয় না।',
            style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHifzCountChip('শিখছেন', counts['learning']!),
              _buildHifzCountChip('সাম্প্রতিক', counts['recent']!),
              _buildHifzCountChip('প্রতিষ্ঠিত', counts['established']!),
              _buildHifzCountChip('পুনর্বলন', counts['reinforcement']!),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('গত ৭ দিনের সারাংশ', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'নতুন মুখস্থ: ${TriCalendarHelper.toBnNum(weeklyStats.sabaqPagesLearned)} পৃষ্ঠা · '
                  'সবকি: ${TriCalendarHelper.toBnNum(weeklyStats.completedSabqiAssignments)}/'
                  '${TriCalendarHelper.toBnNum(weeklyStats.sabqiAssignments)} · '
                  'মনজিল: ${TriCalendarHelper.toBnNum(weeklyStats.completedManzilAssignments)}/'
                  '${TriCalendarHelper.toBnNum(weeklyStats.manzilAssignments)}',
                  style: GoogleFonts.notoSansBengali(fontSize: 11),
                ),
                Text(
                  'রেকর্ড করা মূল্যায়ন: ${TriCalendarHelper.toBnNum(weeklyStats.assessedAssignments)} · '
                  'মন্তব্য: ${TriCalendarHelper.toBnNum(weeklyStats.feedbackEntries)}',
                  style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
                ),
                if ((weeklyStats.sabqiAssignments > 0 &&
                        weeklyStats.completedSabqiAssignments < weeklyStats.sabqiAssignments) ||
                    (weeklyStats.manzilAssignments > 0 &&
                        weeklyStats.completedManzilAssignments < weeklyStats.manzilAssignments)) ...[
                  const SizedBox(height: 8),
                  Text(
                    'কিছু পুনরাবৃত্তি অসম্পূর্ণ ছিল। আপনার সময় ও অভিজ্ঞতা অনুযায়ী নতুন সবকের পরিমাণ কমানোর বিষয় বিবেচনা করতে পারেন।',
                    style: GoogleFonts.notoSansBengali(fontSize: 11, color: const Color(0xFF8A5A00)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'সাম্প্রতিক মূল্যায়ন',
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(height: 8),
          if (recentLogs.isEmpty)
            _buildHifzEmptyCard('পরিকল্পনা তৈরি ও মূল্যায়ন সংরক্ষণ করলে এখানে ইতিহাস দেখা যাবে।')
          else
            ...recentLogs.take(30).map((entry) {
              final tasks = entry.value.hifzAssignments;
              final completed = tasks.where((task) => task.status == 'completed').length;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFF0F5132)),
                  title: Text(
                    TriCalendarHelper.formatTriDateFull(DateTime.tryParse(entry.key) ?? DateTime.now()),
                    style: GoogleFonts.notoSansBengali(fontSize: 12),
                  ),
                  subtitle: Text(
                    '${TriCalendarHelper.toBnNum(completed)}/${TriCalendarHelper.toBnNum(tasks.length)} কাজ সম্পন্ন · '
                    '${tasks.where((task) => task.assessment != null).length}টি মূল্যায়ন',
                    style: GoogleFonts.notoSansBengali(fontSize: 11),
                  ),
                  onTap: () => _changeSelectedDate(DateTime.tryParse(entry.key) ?? DateTime.now()),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHifzCountChip(String label, int count) => Chip(
        label: Text('$label · ${TriCalendarHelper.toBnNum(count)}', style: GoogleFonts.notoSansBengali(fontSize: 11)),
        backgroundColor: const Color(0xFFE8F5E9),
        side: BorderSide.none,
      );

  Widget _buildHafezRoadmap() {
    final weeklyStats = PlannerService.calculateHafezWeeklyStats(
      _plannerModel!,
      weekEnding: DateTime.now(),
    );
    final recentDays = List.generate(14, (index) {
      final date = DateTime.now().subtract(Duration(days: 13 - index));
      final log = _plannerModel!.logs[TriCalendarHelper.formatDateKey(date)];
      final daur = log?.hafezAssignments.where((item) => item.category == 'daur').toList() ?? [];
      return (date: date, total: daur.length, completed: daur.where((item) => item.status == 'completed').length);
    });
    final plannedPages = PlannerService.buildHafezDayPagePlan(_plannerModel!.hafezSettings)
        .fold<int>(0, (total, range) => total + range.$2 - range.$1 + 1);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'দৌর অগ্রগতি',
            style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F5132)),
          ),
          const SizedBox(height: 8),
          Text(
            'নির্বাচিত ${TriCalendarHelper.toBnNum(_plannerModel!.hafezSettings.cycleDays)} দিনের চক্র · '
            'বর্তমান লক্ষ্য ${TriCalendarHelper.toBnNum(plannedPages)} পৃষ্ঠা',
            style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Text(
            'গত ১৪ দিনের দৌর রেকর্ড',
            style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildHifzEmptyCard(
            'গত ৭ দিনে দৌর: ${TriCalendarHelper.toBnNum(weeklyStats.completedDaurAssignments)}/'
            '${TriCalendarHelper.toBnNum(weeklyStats.daurAssignments)} অংশ · '
            'সম্পন্ন ${TriCalendarHelper.toBnNum(weeklyStats.daurPagesCompleted)} পৃষ্ঠা · '
            'দুর্বল অংশ: ${TriCalendarHelper.toBnNum(weeklyStats.completedWeakReviews)}/'
            '${TriCalendarHelper.toBnNum(weeklyStats.weakReviewAssignments)} পুনরাবৃত্তি · '
            'নির্ধারিত দুর্বল রেঞ্জ ${TriCalendarHelper.toBnNum(weeklyStats.weakPortionsDue)}টি',
          ),
          const SizedBox(height: 8),
          ...recentDays.reversed.map((day) {
            final label = TriCalendarHelper.formatTriDateFull(day.date);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                day.total > 0 && day.completed == day.total ? Icons.check_circle : Icons.history,
                color: day.total > 0 && day.completed == day.total ? const Color(0xFF0F5132) : Colors.grey[500],
              ),
              title: Text(label, style: GoogleFonts.notoSansBengali(fontSize: 11)),
              subtitle: Text(
                day.total == 0
                    ? 'পরিকল্পনা তৈরি হয়নি'
                    : '${TriCalendarHelper.toBnNum(day.completed)}/${TriCalendarHelper.toBnNum(day.total)} অংশ সম্পন্ন',
                style: GoogleFonts.notoSansBengali(fontSize: 10),
              ),
              onTap: () => _changeSelectedDate(day.date),
            );
          }),
          const SizedBox(height: 12),
          _buildHifzEmptyCard(
            'দুর্বল রেঞ্জ দৌর তালিকার পাশাপাশি অতিরিক্ত পুনরাবৃত্তি হিসেবে রাখা হয়; এগুলো মূল দৌর থেকে বাদ যায় না।',
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedRoadmap(String mode) {
    final startDateText = _plannerModel!.planStartDate;
    final startDate = DateTime.tryParse(startDateText ?? '');
    if (startDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          'আপনার তৈরি করা দৈনিক রোডম্যাপ এখানে দেখা যাবে।',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansBengali(color: Colors.grey[600]),
        ),
      );
    }

    final itemCount = _plannerModel!.targetDays.clamp(1, PlannerService.totalQuranPages).toInt();
    var completedDays = 0;
    for (var index = 0; index < itemCount; index++) {
      final date = startDate.add(Duration(days: index));
      final key = TriCalendarHelper.formatDateKey(date);
      if (_plannerModel!.logs[key]?.status == 'completed') completedDays++;
    }
    final remainingDays = itemCount - completedDays;
    final endDate = startDate.add(Duration(days: itemCount - 1));
    final endDateLabel =
        '${TriCalendarHelper.toBnNum(endDate.day)}/${TriCalendarHelper.toBnNum(endDate.month)}/${TriCalendarHelper.toBnNum(endDate.year)}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আপনার দৈনিক রোডম্যাপ (${TriCalendarHelper.toBnNum(itemCount)} দিন)',
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F5132),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'সম্পন্ন ${TriCalendarHelper.toBnNum(completedDays)} / ${TriCalendarHelper.toBnNum(itemCount)} দিন · বাকি ${TriCalendarHelper.toBnNum(remainingDays)} দিন · লক্ষ্য সমাপ্তি $endDateLabel',
            style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            'কোনো দিন খুলে সেই দিনের হিসেব দেখতে আজকের ফোকাসে যান।',
            style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 330,
            child: ListView.separated(
              itemCount: itemCount,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final date = startDate.add(Duration(days: index));
                final key = TriCalendarHelper.formatDateKey(date);
                final log = _plannerModel!.logs[key];
                final task = mode == 'hafiz'
                    ? log?.dourPara
                    : mode == 'student'
                        ? [log?.sabak, log?.sabki, log?.studentDour]
                            .where((value) => value != null && value.trim().isNotEmpty)
                            .join(' · ')
                        : log?.generalTilawat;
                final isCompleted = log?.status == 'completed';

                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                    child: Text(
                      TriCalendarHelper.toBnNum(index + 1),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F5132),
                      ),
                    ),
                  ),
                  title: Text(
                    key,
                    style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    task == null || task.isEmpty ? 'এই দিনের পরিকল্পনা নেই' : task,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[700]),
                  ),
                  trailing: Icon(
                    isCompleted ? Icons.check_circle : Icons.chevron_right,
                    color: isCompleted ? const Color(0xFF0F5132) : Colors.grey[500],
                    size: 20,
                  ),
                  onTap: () {
                    _changeSelectedDate(date);
                    _tabController.animateTo(0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.notoSansBengali(fontSize: 12, height: 1.5, color: Colors.grey[700]),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 3: DIARY & NOTES (কুরআন ডায়েরি ও ভুল খাতা)
  // ----------------------------------------------------
  Widget _buildDiaryTab(String mode) {
    return FutureBuilder<List<PlannerNote>>(
      future: PlannerService.instance.getAllNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode == 'hafiz' || mode == 'student'
                          ? 'ভুল বা মুতাশাবিহাত আয়াত টুকে রাখুন'
                          : 'তিলাওয়াত নোট ও অনুভূতি টুকে রাখুন',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F5132),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _notePageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'পৃষ্ঠা নং',
                              hintText: '১ - ৬১২',
                              labelStyle: GoogleFonts.notoSansBengali(fontSize: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: GoogleFonts.notoSansBengali(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _noteTextController,
                            decoration: InputDecoration(
                              labelText: 'নোটের বিবরণ',
                              hintText: 'ভুল শব্দ বা বিশেষ আয়াত',
                              labelStyle: GoogleFonts.notoSansBengali(fontSize: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: GoogleFonts.notoSansBengali(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('নোট সংরক্ষণ করুন', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _addNote,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'সংরক্ষিত নোটের তালিকা (${TriCalendarHelper.toBnNum(notes.length)} টি)',
                    style: GoogleFonts.notoSansBengali(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (notes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.notes_rounded, size: 36, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'এখনও কোনো নোট সংরক্ষণ করা হয়নি।\nতিলাওয়াতের সময় গুরুত্বপূর্ণ বিষয় এখানে লিখে রাখতে পারবেন।',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0F5132).withOpacity(0.3)),
                            ),
                            child: Text(
                              'পৃষ্ঠা ${TriCalendarHelper.toBnNum(note.page)}',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F5132),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.text,
                                  style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note.dateKey,
                                  style: GoogleFonts.notoSansBengali(fontSize: 10, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 14, color: Color(0xFF0F5132)),
                            label: Text(
                              'পৃষ্ঠায় যান',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F5132),
                              ),
                            ),
                            onPressed: () {
                              widget.onOpenPage(note.page);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteNote(note),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
