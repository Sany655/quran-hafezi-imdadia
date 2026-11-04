import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/planner_model.dart';
import '../utils/tri_calendar_helper.dart';
import 'planner_reminder_service.dart';

class KhatamStats {
  final int totalPagesRead;
  final int totalQuranPages;
  final double percent;
  final int remainingPages;
  final double remainingParas;
  final int completedDays;
  final int targetDays;
  final int dailyRequiredPages;
  final bool isCompleted;

  KhatamStats({
    required this.totalPagesRead,
    this.totalQuranPages = 612,
    required this.percent,
    required this.remainingPages,
    required this.remainingParas,
    required this.completedDays,
    required this.targetDays,
    required this.dailyRequiredPages,
    required this.isCompleted,
  });
}

class PlannerBackupImportResult {
  final bool reminderScheduled;
  final Object? reminderError;

  const PlannerBackupImportResult({
    required this.reminderScheduled,
    this.reminderError,
  });
}

class PlannerService {
  static const int totalQuranPages = 612;
  static const int pagesPerPara = 20;

  static final PlannerService instance = PlannerService._internal();
  PlannerService._internal();

  PlannerModel? _cachedModel;

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/planner_v3.json');
  }

  Future<PlannerModel> getPlannerData() async {
    if (_cachedModel != null) return _cachedModel!;
    final file = await _getStorageFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final data = json.decode(content);
        if (data is! Map) {
          throw const FormatException('Planner data must be a JSON object.');
        }
        _cachedModel = PlannerModel.fromMap(Map<String, dynamic>.from(data));
        return _cachedModel!;
      }
    }
    _cachedModel = PlannerModel(profileMode: 'general', hijriOffset: 0);
    return _cachedModel!;
  }

  Future<void> savePlannerData(PlannerModel model) async {
    final file = await _getStorageFile();
    await file.writeAsString(json.encode(model.toMap()), flush: true);
    _cachedModel = model;
  }

  Future<void> setProfileMode(String mode) async {
    final model = await getPlannerData();
    model.profileMode = mode;
    await savePlannerData(model);
  }

  Future<void> setHijriOffset(int offset) async {
    final model = await getPlannerData();
    model.hijriOffset = offset;
    await savePlannerData(model);
  }

  Future<bool> setReminderSettings({required bool enabled, required String time}) async {
    final model = await getPlannerData();
    model.reminderEnabled = false;
    model.reminderTime = time;
    await savePlannerData(model);

    if (!enabled) {
      await PlannerReminderService.instance.cancelDailyReminder();
      return true;
    }

    try {
      final scheduled = await PlannerReminderService.instance.scheduleDailyReminder(time);
      if (!scheduled) return false;
      model.reminderEnabled = true;
      await savePlannerData(model);
      return true;
    } catch (_) {
      model.reminderEnabled = false;
      await savePlannerData(model);
      rethrow;
    }
  }

  Future<bool?> restoreSavedReminder() async {
    final model = await getPlannerData();
    if (!model.reminderEnabled) return null;

    try {
      final scheduled = await PlannerReminderService.instance.scheduleDailyReminder(model.reminderTime);
      if (!scheduled) {
        model.reminderEnabled = false;
        await savePlannerData(model);
      }
      return scheduled;
    } catch (_) {
      model.reminderEnabled = false;
      await savePlannerData(model);
      rethrow;
    }
  }

  Future<void> setTargetSettings({required int targetDays, required int pagesPerDay}) async {
    final model = await getPlannerData();
    model.targetDays = targetDays;
    model.pagesPerDay = pagesPerDay;
    await savePlannerData(model);
  }

  Future<void> resetProgress() async {
    final model = await getPlannerData();
    model.logs.clear();
    model.planStartDate = null;
    await savePlannerData(model);
  }

  static (int start, int end) hafizParaRangeForDay({
    required int dayIndex,
    required int targetDays,
    required int startPara,
  }) {
    final validDays = targetDays.clamp(1, 30).toInt();
    final validDayIndex = dayIndex.clamp(0, validDays - 1).toInt();
    final validStartPara = startPara.clamp(1, 30).toInt();
    final startIndex = (validDayIndex * 30) ~/ validDays;
    final endIndex = (((validDayIndex + 1) * 30) ~/ validDays) - 1;
    return (
      ((startIndex + validStartPara - 1) % 30) + 1,
      ((endIndex + validStartPara - 1) % 30) + 1,
    );
  }

  Future<String> exportBackup() async {
    final model = await getPlannerData();
    return json.encode(model.toMap());
  }

  Future<PlannerBackupImportResult> importBackup(String jsonStr) async {
    final decoded = json.decode(jsonStr);
    if (decoded is! Map) {
      throw const FormatException('Backup must be a JSON object.');
    }
    final data = Map<String, dynamic>.from(decoded);
    if (data['logs'] != null && data['logs'] is! Map) {
      throw const FormatException('Backup contains an invalid logs section.');
    }
    final profileMode = data['profileMode']?.toString() ?? 'general';
    if (!const {'general', 'student', 'hafiz'}.contains(profileMode)) {
      throw const FormatException('Backup contains an unknown planner profile.');
    }
    final model = PlannerModel.fromMap(data);
    final wantsReminder = model.reminderEnabled;
    model.reminderEnabled = false;
    await savePlannerData(model);
    if (!wantsReminder) {
      try {
        await PlannerReminderService.instance.cancelDailyReminder();
        return const PlannerBackupImportResult(reminderScheduled: true);
      } catch (error) {
        return PlannerBackupImportResult(reminderScheduled: false, reminderError: error);
      }
    }
    try {
      final reminderScheduled = await PlannerReminderService.instance.scheduleDailyReminder(model.reminderTime);
      if (reminderScheduled) {
        model.reminderEnabled = true;
        await savePlannerData(model);
      }
      return PlannerBackupImportResult(reminderScheduled: reminderScheduled);
    } catch (error) {
      return PlannerBackupImportResult(reminderScheduled: false, reminderError: error);
    }
  }

  Future<void> saveDayLog(String dateKey, DayLog log) async {
    final model = await getPlannerData();
    model.logs[dateKey] = log;
    await savePlannerData(model);
  }

  Future<void> addNote(String dateKey, int page, String text) async {
    final model = await getPlannerData();
    if (!model.logs.containsKey(dateKey)) {
      model.logs[dateKey] = DayLog();
    }
    model.logs[dateKey]!.notes.add(
      PlannerNote(
        id: DateTime.now().millisecondsSinceEpoch,
        page: page,
        text: text,
        dateKey: dateKey,
      ),
    );
    await savePlannerData(model);
  }

  Future<void> deleteNote(String dateKey, int noteId) async {
    final model = await getPlannerData();
    if (model.logs.containsKey(dateKey)) {
      model.logs[dateKey]!.notes.removeWhere((n) => n.id == noteId);
      await savePlannerData(model);
    }
  }

  Future<List<PlannerNote>> getAllNotes() async {
    final model = await getPlannerData();
    final all = <PlannerNote>[];
    model.logs.forEach((dateKey, dayLog) {
      all.addAll(dayLog.notes);
    });
    all.sort((a, b) => b.id.compareTo(a.id));
    return all;
  }

  KhatamStats calculateKhatamStats(PlannerModel model) {
    int totalPages = 0;
    int completedDaysCount = 0;

    model.logs.forEach((dateKey, dayLog) {
      final pPages = (dayLog.totalDayPages > 0)
          ? dayLog.totalDayPages
          : (dayLog.parasRead * pagesPerPara) + dayLog.pagesRead;

      final actualPages = (pPages > 0)
          ? pPages
          : ((dayLog.status == 'completed' && dayLog.pagesCount > 0) ? dayLog.pagesCount : 0);

      if (actualPages > 0) {
        totalPages += actualPages;
      }

      if (dayLog.status == 'completed' || actualPages > 0) {
        completedDaysCount++;
      }
    });

    final targetDays = model.targetDays > 0 ? model.targetDays : 30;
    final clampedRead = totalPages.clamp(0, totalQuranPages);
    final percent = (totalPages >= totalQuranPages)
        ? 100.0
        : (clampedRead / totalQuranPages) * 100.0;
    final remainingPages = (totalQuranPages - clampedRead).clamp(0, totalQuranPages);
    final remainingParas = remainingPages / pagesPerPara.toDouble();
    final daysLeft = (targetDays - completedDaysCount).clamp(1, targetDays);
    final dailyRequired = (remainingPages > 0) ? (remainingPages / daysLeft).ceil() : 0;
    final isCompleted = totalPages >= totalQuranPages;

    return KhatamStats(
      totalPagesRead: totalPages,
      totalQuranPages: totalQuranPages,
      percent: percent,
      remainingPages: remainingPages,
      remainingParas: remainingParas,
      completedDays: completedDaysCount,
      targetDays: targetDays,
      dailyRequiredPages: dailyRequired,
      isCompleted: isCompleted,
    );
  }

  Future<void> generatePlan({
    required String mode,
    required int targetDays,
    required int startPara,
    required DateTime startDate,
    String goalMode = 'days',
    int pagesPerDay = 20,
  }) async {
    final model = await getPlannerData();
    final validPagesPerDay = pagesPerDay.clamp(1, totalQuranPages).toInt();
    final validTargetDays = mode == 'hafiz'
        ? targetDays.clamp(1, 30).toInt()
        : goalMode == 'pages'
            ? (totalQuranPages / validPagesPerDay).ceil()
            : targetDays.clamp(1, totalQuranPages).toInt();
    final validStartPara = (startPara >= 1 && startPara <= 30) ? startPara : 1;
    model.targetDays = validTargetDays;
    model.pagesPerDay = validPagesPerDay;
    model.roadmapGoalMode = goalMode == 'pages' ? 'pages' : 'days';
    model.planStartDate = TriCalendarHelper.formatDateKey(startDate);

    final startPageOffset = (validStartPara - 1) * pagesPerPara;
    DateTime d = DateTime(startDate.year, startDate.month, startDate.day);

    for (int i = 0; i < validTargetDays; i++) {
      final dKey = TriCalendarHelper.formatDateKey(d);
      if (!model.logs.containsKey(dKey)) {
        model.logs[dKey] = DayLog();
      }

      final rawP1 = goalMode == 'pages' && mode != 'hafiz'
          ? i * validPagesPerDay
          : ((i * totalQuranPages) ~/ validTargetDays);
      final rawP2 = goalMode == 'pages' && mode != 'hafiz'
          ? ((i + 1) * validPagesPerDay).clamp(0, totalQuranPages).toInt()
          : (((i + 1) * totalQuranPages) ~/ validTargetDays);

      final p1 = ((rawP1 + startPageOffset) % totalQuranPages) + 1;
      var p2 = ((rawP2 + startPageOffset - 1) % totalQuranPages) + 1;
      if (rawP2 - rawP1 == 0) p2 = p1;

      final startParaNum = ((p1 - 1) ~/ pagesPerPara) + 1;
      final endParaNum = ((p2 - 1) ~/ pagesPerPara) + 1;

      String planText;
      if (p2 < p1) {
        planText = 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(p1)}-৬১২ এবং ১-${TriCalendarHelper.toBnNum(p2)}';
      } else if (p1 == p2) {
        planText = 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(p1)} (পারা ${TriCalendarHelper.toBnNum(startParaNum)})';
      } else if (startParaNum == endParaNum) {
        planText = 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(p1)} থেকে ${TriCalendarHelper.toBnNum(p2)} (পারা ${TriCalendarHelper.toBnNum(startParaNum)})';
      } else {
        planText = 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(p1)} থেকে ${TriCalendarHelper.toBnNum(p2)} (পারা ${TriCalendarHelper.toBnNum(startParaNum)} - ${TriCalendarHelper.toBnNum(endParaNum)})';
      }

      final dayPages = (rawP2 - rawP1 > 0) ? (rawP2 - rawP1) : 1;

      if (mode == 'general') {
        model.logs[dKey]!.generalTilawat = planText;
        model.logs[dKey]!.dourPara = planText;
        model.logs[dKey]!.pagesCount = dayPages;
        model.logs[dKey]!.status ??= 'pending';
      } else if (mode == 'hafiz') {
        final (pStartPara, pEndPara) = hafizParaRangeForDay(
          dayIndex: i,
          targetDays: validTargetDays,
          startPara: validStartPara,
        );
        String dourText;
        if (pEndPara < pStartPara) {
          dourText =
              'পারা ${TriCalendarHelper.toBnNum(pStartPara)} থেকে ৩০ এবং ১ থেকে ${TriCalendarHelper.toBnNum(pEndPara)}';
        } else if (pStartPara == pEndPara) {
          dourText = 'পারা ${TriCalendarHelper.toBnNum(pStartPara)}';
        } else {
          dourText = 'পারা ${TriCalendarHelper.toBnNum(pStartPara)} থেকে ${TriCalendarHelper.toBnNum(pEndPara)}';
        }
        model.logs[dKey]!.dourPara = dourText;
        model.logs[dKey]!.pagesCount = dayPages;
        model.logs[dKey]!.status ??= 'pending';
      } else {
        model.logs[dKey]!.sabak = planText;
        model.logs[dKey]!.pagesCount = dayPages;
        model.logs[dKey]!.status ??= 'pending';
      }

      d = d.add(const Duration(days: 1));
    }

    await savePlannerData(model);
  }
}
