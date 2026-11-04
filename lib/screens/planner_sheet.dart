import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/planner_model.dart';
import '../services/planner_service.dart';
import '../utils/tri_calendar_helper.dart';

class PlannerSheet extends StatefulWidget {
  final Function(int pageNumber) onOpenPage;

  const PlannerSheet({
    super.key,
    required this.onOpenPage,
  });

  @override
  State<PlannerSheet> createState() => _PlannerSheetState();
}

class _PlannerSheetState extends State<PlannerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlannerModel? _plannerModel;
  bool _isLoading = true;

  DateTime _calendarMonthDate = DateTime.now();
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
    _tabController = TabController(length: 4, vsync: this);
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

  void _changeProfileMode(String mode) async {
    await PlannerService.instance.setProfileMode(mode);
    setState(() {
      _plannerModel?.profileMode = mode;
      _cycleSummary = null;
      if (mode == 'general') {
        _cycleTargetDays = 30;
      } else if (mode == 'hafiz') {
        _cycleTargetDays = 30;
      } else {
        _cycleTargetDays = 30;
      }
    });
  }

  void _saveStatus(String status) async {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    log.status = status;
    await PlannerService.instance.saveDayLog(dateKey, log);
    setState(() {});
    _showSnack(
      (_plannerModel?.profileMode == 'general' ? 'তিলাওয়াত' : _plannerModel?.profileMode == 'student' ? 'পড়ার' : 'দাওর') +
          ' স্ট্যাটাস আপডেট হয়েছে!',
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
          'আলহামদুলিল্লাহ! আপনার নির্বাচন অনুযায়ী আগামী ${TriCalendarHelper.toBnNum(_cycleTargetDays)} দিনের পরিকল্পনা ক্যালেন্ডারে সাজানো হয়েছে।';
    });
    _showSnack('পরিকল্পনা তৈরি সম্পন্ন!');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _plannerModel == null) {
      return Container(
        height: 350,
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F5132)),
        ),
      );
    }

    final mode = _plannerModel!.profileMode;
    final hijriOffset = _plannerModel!.hijriOffset;

    String modalTitle;
    String tab1Title;
    String tab2Title;
    String tab3Title;

    if (mode == 'general') {
      modalTitle = 'কুরআন তিলাওয়াত ট্র্যাকার ও ক্যালেন্ডার';
      tab1Title = '📅 ক্যালেন্ডার ও তিলাওয়াত';
      tab2Title = '🎯 খতম প্ল্যানার';
      tab3Title = '📝 তিলাওয়াত নোট ও আয়াত';
    } else if (mode == 'student') {
      modalTitle = 'হিফজ শিক্ষার্থী রুটিন ও ক্যালেন্ডার';
      tab1Title = '📅 সবক ও ক্যালেন্ডার';
      tab2Title = '🔄 সবক ও দাওর সাইকেল';
      tab3Title = '📝 হিফজ ভুল ও মুতাশাবিহাত';
    } else {
      modalTitle = 'হুফ্ফাজ দাওর রুটিন ও ক্যালেন্ডার';
      tab1Title = '📅 ক্যালেন্ডার ও দাওর';
      tab2Title = '🔄 দাওর সাইকেল';
      tab3Title = '📝 মুতাশাবিহাত ও ভুল খাতা';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F5132),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              modalTitle,
                              style: GoogleFonts.notoSansBengali(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'অফলাইন',
                              style: GoogleFonts.notoSansBengali(
                                color: const Color(0xFF0F5132),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'আজ: ${TriCalendarHelper.formatTriDateFull(DateTime.now(), hijriOffset)}',
                  style: GoogleFonts.notoSansBengali(
                    color: const Color(0xFFFDE68A),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Smart Profile Mode Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF0B3D26),
            child: Row(
              children: [
                _buildModeButton('general', '🌿 সাধারণ তিলাওয়াত', mode == 'general'),
                const SizedBox(width: 6),
                _buildModeButton('student', '📖 শিক্ষার্থী', mode == 'student'),
                const SizedBox(width: 6),
                _buildModeButton('hafiz', '🌟 হুফ্ফাজ মোড', mode == 'hafiz'),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF0F5132),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF0F5132),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.notoSansBengali(fontSize: 12),
              tabs: [
                Tab(text: tab1Title),
                Tab(text: tab2Title),
                Tab(text: tab3Title),
                const Tab(text: '⚙️ ব্যাকআপ ও সেটিংস'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarTabView(mode, hijriOffset),
                _buildCycleTabView(mode),
                _buildNotesListTabView(mode),
                _buildSettingsTabView(hijriOffset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String modeKey, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeProfileMode(modeKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.notoSansBengali(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: CALENDAR & DAILY TRACKER
  // ==========================================
  Widget _buildCalendarTabView(String mode, int hijriOffset) {
    final firstDayOfMonth = DateTime(_calendarMonthDate.year, _calendarMonthDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_calendarMonthDate.year, _calendarMonthDate.month);
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final gMonth = TriCalendarHelper.gregorianMonthsBn[_calendarMonthDate.month - 1];
    final gYear = TriCalendarHelper.toBnNum(_calendarMonthDate.year);
    final midMonthDate = DateTime(_calendarMonthDate.year, _calendarMonthDate.month, 15);
    final bnMid = TriCalendarHelper.getBengaliDate(midMonthDate);
    final hjMid = TriCalendarHelper.getHijriDate(midMonthDate, hijriOffset);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF0F5132)),
                  onPressed: () {
                    setState(() {
                      _calendarMonthDate = DateTime(
                        _calendarMonthDate.year,
                        _calendarMonthDate.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Column(
                  children: [
                    Text(
                      '$gMonth $gYear',
                      style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${bnMid.monthName} ${TriCalendarHelper.toBnNum(bnMid.year)} • ${hjMid.monthName} ${TriCalendarHelper.toBnNum(hjMid.year)}',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 11,
                        color: const Color(0xFF0F5132),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF0F5132)),
                  onPressed: () {
                    setState(() {
                      _calendarMonthDate = DateTime(
                        _calendarMonthDate.year,
                        _calendarMonthDate.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Weekdays
          Row(
            children: const ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'].map((day) {
              final isFri = day == 'শুক্র';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isFri ? const Color(0xFF0F5132) : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // 7-column Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startWeekday + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox.shrink();
              }
              final dayNum = index - startWeekday + 1;
              final cellDate = DateTime(_calendarMonthDate.year, _calendarMonthDate.month, dayNum);
              final dateKey = TriCalendarHelper.formatDateKey(cellDate);
              final isSelected = DateUtils.isSameDay(cellDate, _selectedDate);
              final isToday = DateUtils.isSameDay(cellDate, DateTime.now());

              final hj = TriCalendarHelper.getHijriDate(cellDate, hijriOffset);
              final bn = TriCalendarHelper.getBengaliDate(cellDate);
              final log = _plannerModel!.logs[dateKey];
              final hasNotes = log != null && log.notes.isNotEmpty;
              final status = log?.status;

              Color? bgColor = Colors.white;
              Color borderColor = Colors.grey[300]!;

              if (isSelected) {
                bgColor = const Color(0xFFE8F5E9);
                borderColor = const Color(0xFF0F5132);
              } else if (isToday) {
                bgColor = const Color(0xFFFFFBEB);
                borderColor = const Color(0xFFD4AF37);
              } else if (cellDate.weekday == DateTime.friday || hj.isAyyamAlBeed || hj.isRamadan) {
                bgColor = const Color(0xFFF0FDF4);
                borderColor = const Color(0xFFA7F3D0);
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = cellDate;
                    _updateSelectedDateControllers();
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: Hijri date + dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            TriCalendarHelper.toBnNum(hj.day),
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 8,
                              color: const Color(0xFF0F5132),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              if (status == 'completed')
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (status == 'partial')
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasNotes) ...[
                                const SizedBox(width: 2),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      // Gregorian Day
                      Text(
                        TriCalendarHelper.toBnNum(dayNum),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isToday ? const Color(0xFFB45309) : Colors.grey[900],
                        ),
                      ),
                      // Bengali Day
                      Text(
                        TriCalendarHelper.toBnNum(bn.day),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 8,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Selected Day Card
          _buildSelectedDayCard(mode, hijriOffset),
        ],
      ),
    );
  }

  Widget _buildSelectedDayCard(String mode, int hijriOffset) {
    final dateKey = TriCalendarHelper.formatDateKey(_selectedDate);
    final log = _plannerModel!.logs[dateKey] ?? DayLog();
    final hj = TriCalendarHelper.getHijriDate(_selectedDate, hijriOffset);
    final isFriday = _selectedDate.weekday == DateTime.friday;

    String? specialBadge;
    if (hj.isAyyamAlBeed) {
      specialBadge = 'আইয়ামে বীজ (নফল রোজা)';
    } else if (isFriday) {
      specialBadge = "জুমু'আতুল মুবারক";
    } else if (hj.isRamadan) {
      specialBadge = 'পবিত্র মাহে রমাদান';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'নির্বাচিত দিন',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    Text(
                      TriCalendarHelper.formatTriDateFull(_selectedDate, hijriOffset),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (specialBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    specialBadge,
                    style: GoogleFonts.notoSansBengali(
                      color: const Color(0xFF0F5132),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 18),

          // Mode Specific Field
          if (mode == 'general') ...[
            Text('আজকের তিলাওয়াত:', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _generalTilawatController,
                    style: GoogleFonts.notoSansBengali(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'যেমন: ৫ পৃষ্ঠা / ১ পারা...',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5132),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveGeneralTilawat,
                  child: Text('সংরক্ষণ', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                ),
              ],
            ),
          ] else if (mode == 'student') ...[
            Text('হিফজ শিক্ষার্থী রুটিন:', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _studentSabakController,
              style: GoogleFonts.notoSansBengali(fontSize: 12),
              decoration: InputDecoration(
                labelText: '১. সবক (নতুন পড়া)',
                labelStyle: GoogleFonts.notoSansBengali(fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _studentSabkiController,
              style: GoogleFonts.notoSansBengali(fontSize: 12),
              decoration: InputDecoration(
                labelText: '২. সবকী (সাম্প্রতিক পারা)',
                labelStyle: GoogleFonts.notoSansBengali(fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _studentDourController,
              style: GoogleFonts.notoSansBengali(fontSize: 12),
              decoration: InputDecoration(
                labelText: '৩. দাওর (পুরনো রিভিশন)',
                labelStyle: GoogleFonts.notoSansBengali(fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5132),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveStudentRoutine,
                child: Text('শিক্ষার্থী রুটিন সংরক্ষণ', style: GoogleFonts.notoSansBengali(fontSize: 12)),
              ),
            ),
          ] else ...[
            Text('আজকের দাওর (পারা):', style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hafizDourController,
                    style: GoogleFonts.notoSansBengali(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'যেমন: পারা ৭, ৮...',
                      hintStyle: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5132),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveHafizDour,
                  child: Text('সংরক্ষণ', style: GoogleFonts.notoSansBengali(fontSize: 12)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Daily Status Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (mode == 'general' ? 'তিলাওয়াত স্ট্যাটাস:' : mode == 'student' ? 'পড়ার স্ট্যাটাস:' : 'দাওর স্ট্যাটাস:'),
                style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildStatusButton('completed', '✅ সম্পন্ন', log.status == 'completed'),
                  const SizedBox(width: 4),
                  _buildStatusButton('partial', '⏳ আংশিক', log.status == 'partial'),
                  const SizedBox(width: 4),
                  _buildStatusButton('pending', '❌ বাকি', log.status == 'pending'),
                ],
              ),
            ],
          ),
          const Divider(height: 18),

          // Note form
          Text(
            (mode == 'general' ? 'তিলাওয়াত নোট বা প্রিয় আয়াত:' : mode == 'student' ? 'সবক ও হিফজ ভুল নোট:' : 'মুতাশাবিহাত ও সেলফ-কারেকশন নোট:'),
            style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 75,
                child: TextField(
                  controller: _notePageController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.notoSansBengali(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'পৃষ্ঠা (১-৬১২)',
                    hintStyle: GoogleFonts.notoSansBengali(fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _noteTextController,
                  style: GoogleFonts.notoSansBengali(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: (mode == 'general' ? 'আয়াতের শিক্ষা বা নোট...' : 'প্যাঁচ বা ভুলের বিবরণ...'),
                    hintStyle: GoogleFonts.notoSansBengali(fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5132),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _addNote,
                child: Text('+ যোগ', style: GoogleFonts.notoSansBengali(fontSize: 12)),
              ),
            ],
          ),

          // Notes List for this day
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...log.notes.map((note) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5132),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'পৃষ্ঠা ${TriCalendarHelper.toBnNum(note.page)}',
                      style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(note.text, style: GoogleFonts.notoSansBengali(fontSize: 11)),
                  ),
                  TextButton(
                    onPressed: () => widget.onOpenPage(note.page),
                    child: Text('📖 পৃষ্ঠা খুলুন', style: GoogleFonts.notoSansBengali(fontSize: 11, color: const Color(0xFF0F5132), fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    onPressed: () => _deleteNote(note),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusButton(String statusKey, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _saveStatus(statusKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: KHATAM / DOUR CYCLE GENERATOR
  // ==========================================
  Widget _buildCycleTabView(String mode) {
    String title;
    String desc;
    String btnLabel;
    List<Map<String, dynamic>> options;

    if (mode == 'general') {
      title = 'সহজ কুরআন খতম প্ল্যানার';
      desc = 'আপনি কত দিনে পুরো কুরআন তিলাওয়াত শেষ করতে চান নির্বাচন করুন। ক্যালেন্ডার স্বয়ংক্রিয়ভাবে প্রতিদিনের পড়ার লক্ষ্য বণ্টন করে দেবে।';
      btnLabel = 'খতম পরিকল্পনা তৈরি করুন';
      options = [
        {'days': 30, 'label': '৩০ দিনে খতম (প্রতিদিন ১ পারা / ২০ পৃষ্ঠা)'},
        {'days': 60, 'label': '৬০ দিনে খতম (প্রতিদিন আধা পারা / ১০ পৃষ্ঠা)'},
        {'days': 90, 'label': '৯০ দিনে খতম (প্রতিদিন ৭ পৃষ্ঠা)'},
        {'days': 120, 'label': '১২০ দিনে খতম (প্রতিদিন ৫ পৃষ্ঠা)'},
        {'days': 365, 'label': '১ বছরে খতম (প্রতিদিন ১-২ পৃষ্ঠা)'},
      ];
    } else if (mode == 'student') {
      title = 'হিফজ সবক ও দাওর সাইকেল';
      desc = 'হিফজ শিক্ষার্থী হিসেবে আপনি কত দিনে রিভিশন সাইকেল শেষ করতে চান নির্বাচন করুন।';
      btnLabel = 'হিফজ সাইকেল তৈরি করুন';
      options = [
        {'days': 15, 'label': '১৫ দিনে রিভিশন (প্রতিদিন ২ পারা)'},
        {'days': 20, 'label': '২০ দিনে রিভিশন (প্রতিদিন ১.৫ পারা)'},
        {'days': 30, 'label': '৩০ দিনে রিভিশন (প্রতিদিন ১ পারা)'},
        {'days': 60, 'label': '৬০ দিনে রিভিশন (প্রতিদিন আধা পারা)'},
      ];
    } else {
      title = 'স্বয়ংক্রিয় দাওর সাইকেল ক্যালকুলেটর';
      desc = 'আপনি কত দিনে পুরো কুরআন দাওর (রিভিশন) শেষ করতে চান নির্বাচন করুন। ক্যালেন্ডার স্বয়ংক্রিয়ভাবে প্রতিদিনের জন্য নির্ধারিত পারার তালিকা তৈরি করে দেবে।';
      btnLabel = 'দাওর সাইকেল তৈরি করুন';
      options = [
        {'days': 7, 'label': '৭ দিনে খতম (প্রতিদিন ৪-৫ পারা)'},
        {'days': 10, 'label': '১০ দিনে খতম (প্রতিদিন ৩ পারা)'},
        {'days': 15, 'label': '১৫ দিনে খতম (প্রতিদিন ২ পারা)'},
        {'days': 20, 'label': '২০ দিনে খতম (প্রতিদিন ১.৫ পারা)'},
        {'days': 30, 'label': '৩০ দিনে খতম (প্রতিদিন ১ পারা)'},
      ];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),

                // Days selection
                Text('সময়সীমা:', style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: options.any((o) => o['days'] == _cycleTargetDays) ? _cycleTargetDays : options.first['days'] as int,
                      isExpanded: true,
                      style: GoogleFonts.notoSansBengali(color: Colors.grey[900], fontSize: 12),
                      items: options.map((opt) {
                        return DropdownMenuItem<int>(
                          value: opt['days'] as int,
                          child: Text(opt['label'].toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _cycleTargetDays = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Start para
                Text('শুরুর পারা (১-৩০):', style: GoogleFonts.notoSansBengali(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.notoSansBengali(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '১',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (v) {
                    final p = int.tryParse(v);
                    if (p != null && p >= 1 && p <= 30) {
                      _cycleStartPara = p;
                    }
                  },
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _generateCycle,
                    child: Text(btnLabel, style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          if (_cycleSummary != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F5132),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ পরিকল্পনা সফলভাবে তৈরি হয়েছে!',
                    style: GoogleFonts.notoSansBengali(color: const Color(0xFFFDE68A), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cycleSummary!,
                    style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: ALL NOTES LIST (WITH PAGE JUMP)
  // ==========================================
  Widget _buildNotesListTabView(String mode) {
    return FutureBuilder<List<PlannerNote>>(
      future: PlannerService.instance.getAllNotes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0F5132)));
        }
        final notes = snapshot.data!;
        if (notes.isEmpty) {
          final emptyMsg = (mode == 'general')
              ? 'এখনো কোনো তিলাওয়াত নোট লেখা হয়নি। ক্যালেন্ডার থেকে যেকোনো দিনে আপনার পছন্দের আয়াত বা নোট লিখে রাখতে পারেন।'
              : (mode == 'student')
              ? 'এখনো কোনো হিফজ ভুলের নোট নেই। উস্তাদকে পড়া দেওয়ার সময় যেসব আয়াতে সমস্যা হয় তা ক্যালেন্ডারের দিন থেকে টুকে রাখুন।'
              : 'এখনো কোনো মুতাশাবিহাত নোট লেখা হয়নি। দাওরের সময় যেসব আয়াতে প্যাঁচ লাগে তা ক্যালেন্ডারের দিন থেকে পৃষ্ঠা নম্বরসহ লিখে রাখুন।';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
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
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F5132),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'পৃষ্ঠা ${TriCalendarHelper.toBnNum(note.page)}',
                          style: GoogleFonts.notoSansBengali(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note.dateKey,
                        style: GoogleFonts.notoSansBengali(fontSize: 9, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      note.text,
                      style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => widget.onOpenPage(note.page),
                    child: Text('📖 পৃষ্ঠা খুলুন', style: GoogleFonts.notoSansBengali(fontSize: 11)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: () => _deleteNote(note),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 4: SETTINGS & BACKUP
  // ==========================================
  Widget _buildSettingsTabView(int hijriOffset) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'চাঁদ দেখা অনুযায়ী হিজরি তারিখ সমন্বয়:',
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'বাংলাদেশে চাঁদ দেখার ওপর ভিত্তি করে হিজরি তারিখ ১ বা ২ দিন সমন্বয় করতে পারেন।',
                  style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [-2, -1, 0, 1, 2].map((offset) {
                    final isSelected = offset == hijriOffset;
                    final label = (offset > 0 ? '+$offset' : '$offset') + ' দিন';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(
                          label,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0F5132),
                        onSelected: (val) async {
                          if (val) {
                            await PlannerService.instance.setHijriOffset(offset);
                            setState(() {
                              _plannerModel?.hijriOffset = offset;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sadaqah Jariyah Pledge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volunteer_activism, color: Color(0xFF0F5132)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'সম্পূর্ণ অফলাইন ও সাদাকায়ে জারিয়া। কোনো ইন্টারনেট ও বিজ্ঞাপন ছাড়াই কুরআন পড়া ও দাওর সহজ করার জন্য প্রস্তুতকৃত।',
                    style: GoogleFonts.notoSansBengali(fontSize: 11, color: const Color(0xFF0F5132)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
