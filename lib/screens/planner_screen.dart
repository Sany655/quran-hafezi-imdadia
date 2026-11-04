import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/planner_model.dart';
import '../services/planner_service.dart';
import '../utils/tri_calendar_helper.dart';

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

  DateTime _selectedDate = DateTime.now();

  // Integer trackers for Today's Focus
  int _currentParasRead = 0;
  int _currentPagesRead = 0;
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
  final TextEditingController _targetDaysController = TextEditingController(text: '30');
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
    super.dispose();
  }

  Future<void> _loadData() async {
    final model = await PlannerService.instance.getPlannerData();
    if (mounted) {
      setState(() {
        _plannerModel = model;
        _isLoading = false;
        _cycleTargetDays = model.targetDays > 0 ? model.targetDays : 30;
        _targetDaysController.text = _cycleTargetDays.toString();
        _updateSelectedDateControllers();
      });
    }
  }

  void _updateSelectedDateControllers() {
    if (_plannerModel == null) return;
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();

    _currentParasRead = log.parasRead.clamp(0, 30);
    _currentPagesRead = log.pagesRead.clamp(0, 612);

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

  void _toggleCurrentDayStatus() async {
    if (_plannerModel == null) return;
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    final currentStatus = log.status;
    final newStatus = (currentStatus == 'completed') ? 'pending' : 'completed';
    log.status = newStatus;
    await PlannerService.instance.saveDayLog(dateKey, log);
    await _loadData();
    _showSnack(
      newStatus == 'completed'
          ? 'আলহামদুলিল্লাহ! পড়া সম্পন্ন চিহ্নিত করা হয়েছে।'
          : 'স্ট্যাটাস পরিবর্তন করা হয়েছে।',
    );
  }

  void _saveDayReading() async {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();

    final totalPages = (_currentParasRead * PlannerService.pagesPerPara) + _currentPagesRead;

    log.parasRead = _currentParasRead;
    log.pagesRead = _currentPagesRead;
    log.totalDayPages = totalPages;

    if (totalPages > 0) {
      log.status = 'completed';
    }

    final mode = _plannerModel?.profileMode ?? 'general';
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
    _showSnack('আজকের তিলাওয়াত হিসেব সংরক্ষিত হয়েছে!');
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
    await PlannerService.instance.addNote(dateKey, page, text);
    _noteTextController.clear();
    await _loadData();
    _showSnack('নোট যুক্ত হয়েছে!');
  }

  void _deleteNote(PlannerNote note) async {
    await PlannerService.instance.deleteNote(note.dateKey, note.id);
    await _loadData();
    _showSnack('নোট মুছে ফেলা হয়েছে');
  }

  void _setTargetDays(int days) {
    final validDays = days.clamp(1, 1000);
    setState(() {
      _cycleTargetDays = validDays;
      _targetDaysController.text = validDays.toString();
    });
  }

  void _generateCycle() async {
    final mode = _plannerModel?.profileMode ?? 'general';
    final targetDays = int.tryParse(_targetDaysController.text.trim()) ?? _cycleTargetDays;
    final validTargetDays = targetDays.clamp(1, 1000);

    await PlannerService.instance.generatePlan(
      mode: mode,
      targetDays: validTargetDays,
      startPara: _cycleStartPara,
      startDate: _selectedDate,
    );
    await _loadData();
    setState(() {
      _cycleTargetDays = validTargetDays;
      _cycleSummary =
          'আলহামদুলিল্লাহ! আপনার নির্বাচন অনুযায়ী আগামী ${TriCalendarHelper.toBnNum(validTargetDays)} দিনের রোডম্যাপ প্রস্তুত করা হয়েছে।';
    });
    _showSnack('নতুন রোডম্যাপ তৈরি সম্পন্ন!');
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

  void _showSettingsDialog() {
    if (_plannerModel == null) return;
    String selectedMode = _plannerModel!.profileMode;
    int currentOffset = _plannerModel!.hijriOffset;
    bool reminderEnabled = _plannerModel!.reminderEnabled;
    String reminderTime = _plannerModel!.reminderTime;

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
                      subtitle: 'সবক, সবকি ও আমপারা রুটিন',
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
                              final jsonStr = await PlannerService.instance.exportBackup();
                              await Share.share(jsonStr, subject: 'কুরআন প্ল্যানার ব্যাকআপ ডেটা');
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
                                await PlannerService.instance.resetProgress();
                                await _loadData();
                                if (context.mounted) Navigator.pop(ctx);
                                _showSnack('প্ল্যানার রিসেট সম্পন্ন হয়েছে!');
                              }
                            },
                          ),
                        ),
                      ],
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
                          await PlannerService.instance.setProfileMode(selectedMode);
                          await PlannerService.instance.setHijriOffset(currentOffset);
                          await PlannerService.instance.setReminderSettings(
                            enabled: reminderEnabled,
                            time: reminderTime,
                          );
                          await _loadData();
                          if (context.mounted) Navigator.pop(ctx);
                          _showSnack('সেটিংস সংরক্ষিত হয়েছে!');
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
    if (_isLoading || _plannerModel == null) {
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
                        'আজ: ${TriCalendarHelper.formatTriDateFull(DateTime.now(), hijriOffset)}',
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
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    final isCompleted = log.status == 'completed';

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
                              ? 'আজকের তিলাওয়াত হিসেব'
                              : mode == 'student'
                                  ? 'আজকের সবক ও পৃষ্ঠা হিসেব'
                                  : 'আজকের দাওর ও পৃষ্ঠা হিসেব',
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
                      'পড়া হয়েছে: ${TriCalendarHelper.toBnNum(stats.totalPagesRead)} / ৬১২ পৃষ্ঠা',
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
                      'মাশাআল্লাহ! আপনি পূর্ণ ৬১২ পৃষ্ঠা (৩০ পারা) তিলাওয়াত সম্পন্ন করেছেন! আল্লাহ কবুল করুন।',
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
    final dates = List.generate(11, (i) => now.subtract(Duration(days: 7 - i)));

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
                'গত ৭ দিনের ধারাবাহিকতা (Streak)',
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
  Widget _buildRoadmapTab(String mode) {
    final stats = PlannerService.instance.calculateKhatamStats(_plannerModel!);
    final targetDaysInput = int.tryParse(_targetDaysController.text.trim()) ?? _cycleTargetDays;
    final validDays = targetDaysInput > 0 ? targetDaysInput : 1;

    final remainingPages = stats.remainingPages > 0 ? stats.remainingPages : 612;
    final dynamicDailyPace = (remainingPages / validDays).ceil();
    final estCompletionDate = _selectedDate.add(Duration(days: validDays));

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
                  'আপনার সুবিধাজনক লক্ষ্য দিন লিখুন, অ্যাপ স্বয়ংক্রিয়ভাবে প্রতিদিনের সুনির্দিষ্ট পৃষ্ঠা রোডম্যাপ সাজিয়ে দেবে।',
                  style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),

                // Integer Input for Target Days
                Text(
                  'টার্গেট সময়সীমা (দিন সংখ্যা লিখুন):',
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
                        onPressed: () {
                          final current = int.tryParse(_targetDaysController.text.trim()) ?? _cycleTargetDays;
                          _setTargetDays(current - 1);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _targetDaysController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'দিন সংখ্যা',
                          ),
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5132),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val) ?? 30;
                            setState(() {
                              _cycleTargetDays = parsed.clamp(1, 1000);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStepperButton(
                        icon: Icons.add,
                        onPressed: () {
                          final current = int.tryParse(_targetDaysController.text.trim()) ?? _cycleTargetDays;
                          _setTargetDays(current + 1);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'দিন',
                        style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Quick preset chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [3, 5, 7, 10, 15, 20, 30, 60, 90].map((d) {
                    final isSel = _cycleTargetDays == d;
                    return InkWell(
                      onTap: () => _setTargetDays(d),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF0F5132) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel ? const Color(0xFF0F5132) : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          '${TriCalendarHelper.toBnNum(d)} দিন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Start Para & Start Date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (d != null) setState(() => _selectedDate = d);
                            },
                            child: Text(
                              '${TriCalendarHelper.toBnNum(_selectedDate.day)}/${TriCalendarHelper.toBnNum(_selectedDate.month)}',
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
                        'অবশিষ্ট পৃষ্ঠা: ${TriCalendarHelper.toBnNum(remainingPages)} পৃষ্ঠা (${TriCalendarHelper.toBnNum((remainingPages / 20.0).toStringAsFixed(1))} পারা)',
                        style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[800]),
                      ),
                      Text(
                        'প্রয়োজনীয় দৈনিক গতি: ${TriCalendarHelper.toBnNum(dynamicDailyPace)} পৃষ্ঠা/দিন (~${TriCalendarHelper.toBnNum((dynamicDailyPace / 20.0).toStringAsFixed(1))} পারা)',
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
