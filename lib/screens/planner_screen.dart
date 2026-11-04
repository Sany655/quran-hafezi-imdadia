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

  // Inputs
  final TextEditingController _generalTilawatController = TextEditingController();
  final TextEditingController _hafizDourController = TextEditingController();
  final TextEditingController _studentSabakController = TextEditingController();
  final TextEditingController _studentSabkiController = TextEditingController();
  final TextEditingController _studentDourController = TextEditingController();

  final TextEditingController _notePageController = TextEditingController();
  final TextEditingController _noteTextController = TextEditingController();

  int _cycleTargetDays = 30;
  int _cycleStartPara = 1;
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
    _generalTilawatController.dispose();
    _hafizDourController.dispose();
    _studentSabakController.dispose();
    _studentSabkiController.dispose();
    _studentDourController.dispose();
    _notePageController.dispose();
    _noteTextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final model = await PlannerService.instance.getPlannerData();
    if (mounted) {
      setState(() {
        _plannerModel = model;
        _isLoading = false;
        _updateSelectedDateControllers();
      });
    }
  }

  void _updateSelectedDateControllers() {
    if (_plannerModel == null) return;
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();

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

  void _toggleCurrentDayStatus() async {
    if (_plannerModel == null) return;
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    final currentStatus = log.status;
    final newStatus = (currentStatus == 'completed') ? 'pending' : 'completed';
    log.status = newStatus;
    await PlannerService.instance.saveDayLog(dateKey, log);
    setState(() {});
    _showSnack(
      newStatus == 'completed'
          ? 'আলহামদুলিল্লাহ! পড়া সম্পন্ন চিহ্নিত করা হয়েছে।'
          : 'স্ট্যাটাস পরিবর্তন করা হয়েছে।',
    );
  }

  void _saveGeneralTilawat() async {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    log.generalTilawat = _generalTilawatController.text.trim();
    log.status ??= 'completed';
    await PlannerService.instance.saveDayLog(dateKey, log);
    setState(() {});
    _showSnack('তিলাওয়াত সংরক্ষিত হয়েছে!');
  }

  void _saveHafizDour() async {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    log.dourPara = _hafizDourController.text.trim();
    log.status ??= 'completed';
    await PlannerService.instance.saveDayLog(dateKey, log);
    setState(() {});
    _showSnack('আজকের দাওর সংরক্ষিত হয়েছে!');
  }

  void _saveStudentRoutine() async {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    log.sabak = _studentSabakController.text.trim();
    log.sabki = _studentSabkiController.text.trim();
    log.studentDour = _studentDourController.text.trim();
    log.status ??= 'completed';
    await PlannerService.instance.saveDayLog(dateKey, log);
    setState(() {});
    _showSnack('শিক্ষার্থী রুটিন সংরক্ষিত হয়েছে!');
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

  void _generateCycle() async {
    final mode = _plannerModel?.profileMode ?? 'general';
    await PlannerService.instance.generatePlan(
      mode: mode,
      targetDays: _cycleTargetDays,
      startPara: _cycleStartPara,
      startDate: _selectedDate,
    );
    await _loadData();
    setState(() {
      _cycleSummary =
          'আলহামদুলিল্লাহ! আপনার নির্বাচন অনুযায়ী আগামী ${TriCalendarHelper.toBnNum(_cycleTargetDays)} দিনের রোডম্যাপ প্রস্তুত করা হয়েছে।';
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
                    // Header
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

                    // Profile Mode Selection
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
                      title: '🌿 সাধারণ তিলাওয়াতকারী',
                      subtitle: 'দৈনিক তিলাওয়াত ও খতম প্ল্যানার',
                      value: 'general',
                      groupValue: selectedMode,
                      onChanged: (val) {
                        setModalState(() => selectedMode = val!);
                      },
                    ),
                    _buildModeTile(
                      title: '📖 হিফজ শিক্ষার্থী',
                      subtitle: 'সবক, সবকি ও আমপারা রুটিন',
                      value: 'student',
                      groupValue: selectedMode,
                      onChanged: (val) {
                        setModalState(() => selectedMode = val!);
                      },
                    ),
                    _buildModeTile(
                      title: '🌟 হুফ্ফাজ মোড',
                      subtitle: 'মঞ্জিল ও দাওর সাইকেল ট্র্যাকার',
                      value: 'hafiz',
                      groupValue: selectedMode,
                      onChanged: (val) {
                        setModalState(() => selectedMode = val!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Reminder Setting
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

                    // Hijri Date Adjustment
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

                    // Backup and Reset actions
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

                    // Save Button
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
              // Tri-Calendar Date Header
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

              // 3 Clean Tabs
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
                    Tab(text: '🌿 আজকের ফোকাস'),
                    Tab(text: '🎯 রোডম্যাপ ও প্ল্যান'),
                    Tab(text: '📝 কুরআনিক ডায়েরি'),
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

    // Calculate Khatam Progress (total completed days)
    int completedDays = 0;
    _plannerModel!.logs.forEach((k, v) {
      if (v.status == 'completed') completedDays++;
    });
    final targetDays = _plannerModel!.targetDays > 0 ? _plannerModel!.targetDays : 30;
    final progress = (completedDays / targetDays).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

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
                              ? 'আজকের তিলাওয়াত'
                              : mode == 'student'
                                  ? 'আজকের সবক ও রুটিন'
                                  : 'আজকের নির্ধারিত দাওর',
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
                      onPressed: _toggleCurrentDayStatus,
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Content depending on profile mode
                if (mode == 'general') ...[
                  Text(
                    'নির্ধারিত অংশ / পৃষ্ঠা:',
                    style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _generalTilawatController,
                    decoration: InputDecoration(
                      hintText: 'যেমন: পারা ১ অথবা পৃষ্ঠা ১ থেকে ২০',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: GoogleFonts.notoSansBengali(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: Text('সংরক্ষণ করুন', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _saveGeneralTilawat,
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
                ] else if (mode == 'hafiz') ...[
                  Text(
                    'আজকের রিভিশন পারা:',
                    style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _hafizDourController,
                    decoration: InputDecoration(
                      hintText: 'যেমন: ৩য় পারা ও ৪র্থ পারা',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: GoogleFonts.notoSansBengali(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: Text('দাওর সংরক্ষণ করুন', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saveHafizDour,
                  ),
                ] else ...[
                  // Student mode
                  Text('আজকের সবক:', style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _studentSabakController,
                    decoration: InputDecoration(
                      hintText: 'পৃষ্ঠা / আয়াতের রেঞ্জ',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: GoogleFonts.notoSansBengali(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text('সবকি ও পেছনের দাওর:', style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
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
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: Text('রুটিন সংরক্ষণ করুন', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saveStudentRoutine,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Khatam Progress Card
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
                        '${TriCalendarHelper.toBnNum(percentage)}% সম্পন্ন',
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
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F5132)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'মোট পড়া হয়েছে: ${TriCalendarHelper.toBnNum(completedDays)} দিন',
                      style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[600]),
                    ),
                    Text(
                      'টার্গেট: ${TriCalendarHelper.toBnNum(targetDays)} দিন',
                      style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
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

  Widget _buildHorizontalDateStrip() {
    final now = DateTime.now();
    // 7 days past to 3 days future
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Generator Card
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
                  'আপনার সুবিধাজনক সময় নির্বাচন করলে অ্যাপ স্বয়ংক্রিয়ভাবে প্রতিদিনের পড়ার টার্গেট রোডম্যাপ সাজিয়ে দেবে।',
                  style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),

                Text(
                  'টার্গেট সময়সীমা:',
                  style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (mode == 'general' ? [30, 60, 90, 120, 365] : [7, 10, 15, 20, 30]).map((days) {
                    final isSel = _cycleTargetDays == days;
                    return ChoiceChip(
                      label: Text(
                        mode == 'general'
                            ? (days == 30 ? '৩০ দিন (১ মাস)' : days == 60 ? '৬০ দিন (২ মাস)' : days == 90 ? '৩ মাস' : days == 120 ? '৪ মাস' : '১ বছর')
                            : '$days দিনের সাইকেল',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: const Color(0xFF0F5132),
                      backgroundColor: Colors.grey[100],
                      onSelected: (val) {
                        if (val) setState(() => _cycleTargetDays = days);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

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

          // Cycle Summary Card
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

          // Daily Target Reference Info
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
              // Add Note Card
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

              // Notes List Header
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

              // Notes List
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
                          // Open Page Button
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
