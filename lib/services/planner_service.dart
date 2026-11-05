import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/quran_db_helper.dart';
import '../models/hifz_model.dart';
import '../models/planner_model.dart';
import '../models/quran_range.dart';
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

class HifzWeeklyStats {
  final int sabaqPagesLearned;
  final int sabqiAssignments;
  final int completedSabqiAssignments;
  final int manzilAssignments;
  final int completedManzilAssignments;
  final int weakPortions;
  final int assessedAssignments;
  final int feedbackEntries;

  const HifzWeeklyStats({
    required this.sabaqPagesLearned,
    required this.sabqiAssignments,
    required this.completedSabqiAssignments,
    required this.manzilAssignments,
    required this.completedManzilAssignments,
    required this.weakPortions,
    required this.assessedAssignments,
    required this.feedbackEntries,
  });
}

class HafezWeeklyStats {
  final int daurAssignments;
  final int completedDaurAssignments;
  final int daurPagesCompleted;
  final int weakReviewAssignments;
  final int completedWeakReviews;
  final int weakPortionsDue;
  final int assessedAssignments;

  const HafezWeeklyStats({
    required this.daurAssignments,
    required this.completedDaurAssignments,
    required this.daurPagesCompleted,
    required this.weakReviewAssignments,
    required this.completedWeakReviews,
    required this.weakPortionsDue,
    required this.assessedAssignments,
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
    final database = QuranDbHelper.instance;
    final storedState = await database.getPlannerStateJson();
    if (storedState != null && storedState.isNotEmpty) {
      _cachedModel = _decodePlannerModel(storedState);
      return _cachedModel!;
    }

    final legacyFile = await _getStorageFile();
    final previousFile = File('${legacyFile.path}.previous');
    final migrationFile = await legacyFile.exists()
        ? legacyFile
        : await previousFile.exists()
            ? previousFile
            : null;
    if (migrationFile != null) {
      final content = await migrationFile.readAsString();
      if (content.isNotEmpty) {
        final model = _decodePlannerModel(content);
        await database.savePlannerStateJson(json.encode(model.toMap()));
        _cachedModel = model;
        return model;
      }
    }

    _cachedModel = PlannerModel(profileMode: 'general', hijriOffset: 0);
    return _cachedModel!;
  }

  PlannerModel _decodePlannerModel(String content) {
    final data = json.decode(content);
    if (data is! Map) {
      throw const FormatException('Planner data must be a JSON object.');
    }
    return PlannerModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> savePlannerData(PlannerModel model) async {
    await QuranDbHelper.instance.savePlannerStateJson(json.encode(model.toMap()));
    _cachedModel = model;
  }

  Future<void> setProfileMode(String mode) async {
    if (!const {'general', 'student', 'hafiz'}.contains(mode)) {
      throw ArgumentError.value(mode, 'mode', 'Unknown planner profile.');
    }
    final model = await getPlannerData();
    model.profileMode = mode;
    await savePlannerData(model);
  }

  Future<void> setHijriOffset(int offset) async {
    final model = await getPlannerData();
    model.hijriOffset = offset;
    await savePlannerData(model);
  }

  Future<void> setCarryForwardMissedTasks(bool enabled) async {
    final model = await getPlannerData();
    model.carryForwardMissedTasks = enabled;
    await savePlannerData(model);
  }

  Future<bool> carryForwardMissedTasksForDate(DateTime date) async {
    final model = await getPlannerData();
    final dateKey = TriCalendarHelper.formatDateKey(date);
    final changed = PlannerService.carryForwardMissedTasks(model, dateKey);
    if (changed) await savePlannerData(model);
    return changed;
  }

  static bool _isHifzCategoryScheduled(String category, int weekday, HifzSettings settings) =>
      switch (category) {
        'sabaq' => settings.sabaqWeekdays.contains(weekday),
        'sabqi' => settings.sabqiWeekdays.contains(weekday),
        'manzil' => settings.manzilWeekdays.contains(weekday),
        _ => false,
      };

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
      if (!scheduled) {
        await PlannerReminderService.instance.cancelDailyReminder();
        return false;
      }
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
        await PlannerReminderService.instance.cancelDailyReminder();
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

  Future<void> setReadingSessions(List<ReadingSession> sessions) async {
    _validateReadingSessions(sessions);
    if (sessions.length > 100) {
      throw const FormatException('At most 100 reader sessions are supported.');
    }
    final model = await getPlannerData();
    model.readerSessions = List<ReadingSession>.from(sessions);
    await savePlannerData(model);
  }

  Future<bool> restoreReaderSessionReminders() async {
    final model = await getPlannerData();
    return PlannerReminderService.instance.scheduleReaderSessionReminders(model.readerSessions);
  }

  Future<void> saveStudentHifzSettings(HifzSettings settings) async {
    if (settings.sabaqStartPage < 1 ||
        settings.sabaqStartPage > totalQuranPages + 1 ||
        settings.sabaqPages < 1 ||
        settings.sabaqPages > totalQuranPages ||
        settings.sabqiLessonCount < 1 ||
        settings.sabqiLessonCount > 100 ||
        settings.sabqiPageCount < 1 ||
        settings.sabqiPageCount > totalQuranPages ||
        settings.manzilPages < 1 ||
        settings.manzilPages > totalQuranPages ||
        settings.manzilCursorPage < 1 ||
        settings.manzilCursorPage > totalQuranPages ||
        !const {'traditional', 'teacher', 'custom'}.contains(settings.revisionMethod) ||
        !const {'lessons', 'pages'}.contains(settings.sabqiRule) ||
        !_validWeekdays(settings.sabaqWeekdays) ||
        !_validWeekdays(settings.sabqiWeekdays) ||
        !_validWeekdays(settings.manzilWeekdays) ||
        !_isValidReminderTime(settings.sabaqReminderTime) ||
        !_isValidReminderTime(settings.sabqiReminderTime) ||
        !_isValidReminderTime(settings.manzilReminderTime)) {
      throw ArgumentError('The Hifz routine settings are invalid.');
    }
    final model = await getPlannerData();
    model.studentHifzSettings = settings;
    await savePlannerData(model);
  }

  static bool _validWeekdays(List<int> weekdays) =>
      weekdays.every((day) => day >= 1 && day <= 7) && weekdays.toSet().length == weekdays.length;

  Future<bool> restoreStudentHifzReminders() async {
    final model = await getPlannerData();
    return PlannerReminderService.instance.scheduleHifzReminders(model.studentHifzSettings);
  }

  static bool _isValidReminderTime(String time) {
    final parts = time.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    return hour != null &&
        minute != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59;
  }

  Future<void> saveHafezSettings(HafezSettings settings) async {
    if (settings.cycleDays < 1 ||
        settings.cycleDays > 365 ||
        settings.daurPages < 1 ||
        settings.daurPages > totalQuranPages ||
        settings.daurCursorPage < 1 ||
        settings.daurCursorPage > totalQuranPages ||
        !_validWeekdays(settings.availableWeekdays) ||
        settings.customRotationCursor < 0 ||
        !_validCustomRotationRanges(settings.customRotationRanges) ||
        (settings.customRotationEnabled && settings.customRotationRanges.isEmpty)) {
      throw ArgumentError('The Daur settings are invalid.');
    }
    if (settings.customRotationRanges.isNotEmpty) {
      final surahs = await QuranDbHelper.instance.getAllSurahs();
      final ayahCounts = {for (final surah in surahs) surah.id: surah.totalAyahs};
      if (settings.customRotationRanges.any((range) => !range.isValid(ayahCounts))) {
        throw ArgumentError('A custom Daur range is invalid.');
      }
      for (var index = 0; index < settings.customRotationRanges.length; index++) {
        for (var other = index + 1; other < settings.customRotationRanges.length; other++) {
          if (quranRangesOverlap(
            settings.customRotationRanges[index],
            settings.customRotationRanges[other],
          )) {
            throw ArgumentError('Custom Daur ranges must not overlap.');
          }
        }
      }
    }
    final model = await getPlannerData();
    model.hafezSettings = settings;
    await savePlannerData(model);
  }

  static bool _validCustomRotationRanges(List<QuranRange> ranges) =>
      ranges.every((range) =>
          range.startPage >= 1 &&
          range.endPage <= totalQuranPages &&
          range.startPage <= range.endPage &&
          range.startSurahId >= 1 &&
          range.endSurahId <= 114 &&
          range.startSurahId <= range.endSurahId &&
          range.startAyahNumber >= 1 &&
          range.endAyahNumber >= 1);

  Future<void> addHafezWeakPortion({
    required QuranRange range,
    required DateTime addedDate,
    required DateTime nextReviewDate,
  }) async {
    final normalizedAddedDate = DateTime(addedDate.year, addedDate.month, addedDate.day);
    final normalizedReviewDate = DateTime(nextReviewDate.year, nextReviewDate.month, nextReviewDate.day);
    if (normalizedReviewDate.isBefore(normalizedAddedDate)) {
      throw ArgumentError('The next review date cannot be before the weak portion was added.');
    }
    final surahs = await QuranDbHelper.instance.getAllSurahs();
    if (!range.isValid({for (final surah in surahs) surah.id: surah.totalAyahs})) {
      throw ArgumentError.value(range, 'range', 'The Quran range is invalid.');
    }
    final model = await getPlannerData();
    if (model.hafezWeakPortions.any((item) => quranRangesOverlap(item.range, range))) {
      throw ArgumentError.value(range, 'range', 'This weak portion overlaps one already recorded.');
    }
    model.hafezWeakPortions.add(
      HafezWeakPortion(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        range: range,
        status: 'weak',
        addedDate: TriCalendarHelper.formatDateKey(normalizedAddedDate),
        nextReviewDate: TriCalendarHelper.formatDateKey(normalizedReviewDate),
      ),
    );
    await savePlannerData(model);
  }

  Future<List<HafezAssignment>> generateHafezDay(DateTime date) async {
    final model = await getPlannerData();
    final dateKey = TriCalendarHelper.formatDateKey(date);
    final log = model.logs.putIfAbsent(dateKey, DayLog.new);
    var changed = PlannerService.carryForwardMissedTasks(model, dateKey);
    if (!log.hafezAssignments.any((item) => item.originalDateKey == null)) {
      final assignments = <HafezAssignment>[];
      if (model.hafezSettings.availableWeekdays.contains(date.weekday)) {
        final customRanges = model.hafezSettings.customRotationEnabled
            ? await _buildHafezCustomDayRanges(model.hafezSettings)
            : [
                for (final pageRange in buildHafezDayPagePlan(model.hafezSettings))
                  await _quranRangeForPages(pageRange.$1, pageRange.$2),
              ];
        for (var index = 0; index < customRanges.length; index++) {
          assignments.add(
            HafezAssignment(
              id: '${dateKey}_daur_$index',
              category: 'daur',
              range: customRanges[index],
            ),
          );
        }
      }

      final weakPortions = model.hafezSettings.availableWeekdays.contains(date.weekday)
          ? model.hafezWeakPortions
              .where((portion) => isHafezWeakPortionDue(portion, date))
              .toList()
            ..sort((a, b) => a.range.startPage.compareTo(b.range.startPage))
          : <HafezWeakPortion>[];
      for (final portion in weakPortions) {
        assignments.add(
          HafezAssignment(
            id: '${dateKey}_weak_${portion.id}',
            category: 'weak',
            weakPortionId: portion.id,
            range: portion.range,
          ),
        );
      }
      final carriedAssignments =
          log.hafezAssignments.where((item) => item.originalDateKey != null).toList();
      final nonOverlappingAssignments = assignments
          .where(
            (planned) => !carriedAssignments.any(
              (carried) =>
                  carried.category == planned.category &&
                  quranRangesOverlap(carried.range, planned.range),
            ),
          )
          .toList();
      log.hafezAssignments = [...nonOverlappingAssignments, ...carriedAssignments];
      changed = true;
    }
    if (changed) await savePlannerData(model);
    return List<HafezAssignment>.unmodifiable(log.hafezAssignments);
  }

  static List<(int startPage, int endPage)> buildHafezDayPagePlan(HafezSettings settings) {
    final start = settings.daurCursorPage.clamp(1, totalQuranPages).toInt();
    final count = settings.daurPages.clamp(1, totalQuranPages).toInt();
    final end = start + count - 1;
    if (end <= totalQuranPages) return [(start, end)];
    return [
      (start, totalQuranPages),
      (1, end - totalQuranPages),
    ];
  }

  static List<({QuranRange range, int startPage, int endPage})> buildHafezCustomDayPagePlan(
    HafezSettings settings,
  ) {
    final ranges = settings.customRotationRanges;
    if (ranges.isEmpty) return const [];
    final totalPages = ranges.fold<int>(
      0,
      (total, range) => total + range.endPage - range.startPage + 1,
    );
    if (totalPages == 0) return const [];
    var cursor = settings.customRotationCursor % totalPages;
    var remainingPages = settings.daurPages.clamp(1, totalPages).toInt();
    final plan = <({QuranRange range, int startPage, int endPage})>[];
    while (remainingPages > 0) {
      var rangeIndex = 0;
      var rangeOffset = cursor;
      while (rangeOffset >= ranges[rangeIndex].endPage - ranges[rangeIndex].startPage + 1) {
        rangeOffset -= ranges[rangeIndex].endPage - ranges[rangeIndex].startPage + 1;
        rangeIndex = (rangeIndex + 1) % ranges.length;
      }
      final source = ranges[rangeIndex];
      final availablePages = source.endPage - source.startPage + 1 - rangeOffset;
      final takePages = availablePages < remainingPages ? availablePages : remainingPages;
      final startPage = source.startPage + rangeOffset;
      plan.add((
        range: source,
        startPage: startPage,
        endPage: startPage + takePages - 1,
      ));
      cursor = (cursor + takePages) % totalPages;
      remainingPages -= takePages;
    }
    return plan;
  }

  Future<List<QuranRange>> _buildHafezCustomDayRanges(HafezSettings settings) async {
    final pageRanges = buildHafezCustomDayPagePlan(settings);
    final result = <QuranRange>[];
    for (final item in pageRanges) {
      final pageRange = await _quranRangeForPages(item.startPage, item.endPage);
      final useSourceStart = item.startPage == item.range.startPage;
      final useSourceEnd = item.endPage == item.range.endPage;
      result.add(
        QuranRange(
          startSurahId: useSourceStart ? item.range.startSurahId : pageRange.startSurahId,
          startAyahNumber: useSourceStart ? item.range.startAyahNumber : pageRange.startAyahNumber,
          endSurahId: useSourceEnd ? item.range.endSurahId : pageRange.endSurahId,
          endAyahNumber: useSourceEnd ? item.range.endAyahNumber : pageRange.endAyahNumber,
          startPage: item.startPage,
          endPage: item.endPage,
        ),
      );
    }
    return result;
  }

  Future<void> recordHafezAssessment({
    required String dateKey,
    required String assignmentId,
    required String assessment,
    required List<String> mistakes,
    required int repetitionCount,
    required String teacherFeedback,
    required bool markCompleted,
  }) async {
    const allowedAssessments = {'perfect', 'minor', 'multiple', 'assistance', 'repeat'};
    const allowedMistakes = {
      'missedAyah',
      'wordSubstitution',
      'hesitation',
      'sequenceConfusion',
      'tajweed',
    };
    if (!allowedAssessments.contains(assessment) ||
        mistakes.any((mistake) => !allowedMistakes.contains(mistake)) ||
        repetitionCount < 0 ||
        repetitionCount > 10000 ||
        (markCompleted && assessment != 'perfect' && assessment != 'minor')) {
      throw ArgumentError('The Hafez assessment contains an invalid value.');
    }
    final model = await getPlannerData();
    final log = model.logs[dateKey];
    if (log == null) throw StateError('The selected day has no Daur plan.');
    final index = log.hafezAssignments.indexWhere((item) => item.id == assignmentId);
    if (index < 0) throw StateError('Daur assignment was not found.');
    final assignment = log.hafezAssignments[index];
    final wasCompleted = assignment.status == 'completed';
    log.hafezAssignments[index] = assignment.copyWith(
      status: markCompleted ? 'completed' : 'partial',
      assessment: assessment,
      mistakes: mistakes,
      repetitionCount: repetitionCount,
      teacherFeedback: teacherFeedback.trim(),
    );

    if (assignment.category == 'weak' && assignment.weakPortionId.isNotEmpty) {
      final portionIndex = model.hafezWeakPortions.indexWhere(
        (portion) => portion.id == assignment.weakPortionId,
      );
      if (portionIndex >= 0) {
        model.hafezWeakPortions[portionIndex] = model.hafezWeakPortions[portionIndex].copyWith(
          status: markCompleted && assessment == 'perfect' ? 'strengthened' : 'reinforcement',
          lastReviewedDate: dateKey,
          nextReviewDate: markCompleted && assessment == 'perfect'
              ? TriCalendarHelper.formatDateKey(DateTime.parse(dateKey).add(const Duration(days: 7)))
              : TriCalendarHelper.formatDateKey(DateTime.parse(dateKey).add(const Duration(days: 1))),
        );
      }
    }

    final daurAssignments =
        log.hafezAssignments.where((item) => item.category == 'daur').toList();
    if (!wasCompleted &&
        daurAssignments.isNotEmpty &&
        daurAssignments.every((item) => item.status == 'completed')) {
      final completedPages = daurAssignments.fold<int>(
        0,
        (total, item) => total + item.range.endPage - item.range.startPage + 1,
      );
      if (model.hafezSettings.customRotationEnabled) {
        final totalPages = model.hafezSettings.customRotationRanges.fold<int>(
          0,
          (total, range) => total + range.endPage - range.startPage + 1,
        );
        if (totalPages > 0) {
          model.hafezSettings = model.hafezSettings.copyWith(
            customRotationCursor:
                (model.hafezSettings.customRotationCursor + completedPages) % totalPages,
          );
        }
      } else {
        model.hafezSettings = model.hafezSettings.copyWith(
          daurCursorPage:
              (model.hafezSettings.daurCursorPage - 1 + completedPages) % totalQuranPages + 1,
        );
      }
    }
    await savePlannerData(model);
  }

  Future<void> addMemorizedPortion({
    required QuranRange range,
    required String status,
    required DateTime date,
  }) async {
    const allowedStatuses = {'learning', 'recent', 'established', 'reinforcement'};
    if (!allowedStatuses.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unknown memorization status.');
    }
    final surahs = await QuranDbHelper.instance.getAllSurahs();
    if (!range.isValid({for (final surah in surahs) surah.id: surah.totalAyahs})) {
      throw ArgumentError.value(range, 'range', 'The Quran range is invalid.');
    }
    final model = await getPlannerData();
    final overlaps = model.memorizedPortions.any(
      (portion) => quranRangesOverlap(range, portion.range),
    );
    if (overlaps) {
      throw ArgumentError.value(range, 'range', 'This portion overlaps existing memorization.');
    }
    model.memorizedPortions.add(
      MemorizedPortion(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        range: range,
        status: status,
        addedDate: TriCalendarHelper.formatDateKey(date),
      ),
    );
    await savePlannerData(model);
  }

  Future<void> updateMemorizedPortionStatus(String portionId, String status) async {
    const allowedStatuses = {'learning', 'recent', 'established', 'reinforcement'};
    if (!allowedStatuses.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unknown memorization status.');
    }
    final model = await getPlannerData();
    final index = model.memorizedPortions.indexWhere((portion) => portion.id == portionId);
    if (index < 0) throw StateError('Memorized portion was not found.');
    model.memorizedPortions[index] = model.memorizedPortions[index].copyWith(status: status);
    await savePlannerData(model);
  }

  Future<void> updateStudentAssignmentRange({
    required String dateKey,
    required String assignmentId,
    required QuranRange range,
  }) async {
    final surahs = await QuranDbHelper.instance.getAllSurahs();
    if (!range.isValid({for (final surah in surahs) surah.id: surah.totalAyahs})) {
      throw ArgumentError.value(range, 'range', 'The Quran range is invalid.');
    }
    final model = await getPlannerData();
    final log = model.logs[dateKey];
    if (log == null) throw StateError('The selected day has no Hifz plan.');
    final index = log.hifzAssignments.indexWhere((item) => item.id == assignmentId);
    if (index < 0) throw StateError('Hifz assignment was not found.');
    final assignment = log.hifzAssignments[index];
    if (assignment.status != 'pending') {
      throw StateError('Only a pending Hifz assignment can be edited.');
    }
    final overlaps = log.hifzAssignments.asMap().entries.any(
      (entry) =>
          entry.key != index &&
          entry.value.category == assignment.category &&
          quranRangesOverlap(entry.value.range, range),
    );
    if (overlaps) throw ArgumentError('The edited range overlaps another assignment in the same layer.');
    log.hifzAssignments[index] = assignment.copyWith(range: range);
    await savePlannerData(model);
  }

  Future<List<HifzAssignment>> generateStudentDay(DateTime date) async {
    final model = await getPlannerData();
    final dateKey = TriCalendarHelper.formatDateKey(date);
    final log = model.logs.putIfAbsent(dateKey, DayLog.new);
    var changed = PlannerService.carryForwardMissedTasks(model, dateKey);
    if (!log.hifzAssignments.any((item) => item.originalDateKey == null)) {
      final assignments = <HifzAssignment>[];
      final pagePlan = buildStudentDayPagePlan(
        settings: model.studentHifzSettings,
        portions: model.memorizedPortions,
        weekday: date.weekday,
      );
      for (var index = 0; index < pagePlan.length; index++) {
        final planned = pagePlan[index];
        assignments.add(
          HifzAssignment(
            id: '${dateKey}_${planned.category}_$index',
            category: planned.category,
            portionId: planned.portionId,
            range: await _quranRangeForPages(planned.startPage, planned.endPage),
          ),
        );
      }
      final carriedAssignments =
          log.hifzAssignments.where((item) => item.originalDateKey != null).toList();
      final nonOverlappingAssignments = assignments
          .where(
            (planned) => !carriedAssignments.any(
              (carried) =>
                  carried.category == planned.category &&
                  quranRangesOverlap(carried.range, planned.range),
            ),
          )
          .toList();
      log.hifzAssignments = [...nonOverlappingAssignments, ...carriedAssignments];
      changed = true;
    }
    if (changed) await savePlannerData(model);
    return List<HifzAssignment>.unmodifiable(log.hifzAssignments);
  }

  static bool carryForwardMissedTasks(PlannerModel model, String dateKey) {
    if (!model.carryForwardMissedTasks) return false;
    final targetDate = DateTime.tryParse(dateKey);
    if (targetDate == null) throw FormatException('Invalid planner date: $dateKey');
    final log = model.logs[dateKey] ?? DayLog();
    final previousLogs = model.logs.entries
        .where((entry) {
          final date = DateTime.tryParse(entry.key);
          return date != null && date.isBefore(targetDate);
        })
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    var changed = false;

    String rootKey(String originDate, String originId) => '$originDate\u0000$originId';
    String rootDate(String? originDate, String logDate) => originDate ?? logDate;

    final latestReaderTasks = <String, (String dateKey, ReadingSessionAssignment task)>{};
    final latestHifzTasks = <String, (String dateKey, HifzAssignment task)>{};
    final latestHafezTasks = <String, (String dateKey, HafezAssignment task)>{};
    for (final entry in previousLogs) {
      for (final task in entry.value.readingSessions) {
        final originDate = rootDate(task.originalDateKey, entry.key);
        final originId = task.originalAssignmentId ?? task.id;
        if (originId.isNotEmpty) latestReaderTasks[rootKey(originDate, originId)] = (entry.key, task);
      }
      for (final task in entry.value.hifzAssignments) {
        final originDate = rootDate(task.originalDateKey, entry.key);
        final originId = task.originalAssignmentId ?? task.id;
        if (originId.isNotEmpty) latestHifzTasks[rootKey(originDate, originId)] = (entry.key, task);
      }
      for (final task in entry.value.hafezAssignments) {
        final originDate = rootDate(task.originalDateKey, entry.key);
        final originId = task.originalAssignmentId ?? task.id;
        if (originId.isNotEmpty) latestHafezTasks[rootKey(originDate, originId)] = (entry.key, task);
      }
    }

    final currentReaderRoots = {
      for (final task in log.readingSessions)
        if ((task.originalAssignmentId ?? task.id).isNotEmpty)
          rootKey(rootDate(task.originalDateKey, dateKey), task.originalAssignmentId ?? task.id),
    };
    final currentHifzRoots = {
      for (final task in log.hifzAssignments)
        if ((task.originalAssignmentId ?? task.id).isNotEmpty)
          rootKey(rootDate(task.originalDateKey, dateKey), task.originalAssignmentId ?? task.id),
    };
    final currentHafezRoots = {
      for (final task in log.hafezAssignments)
        if ((task.originalAssignmentId ?? task.id).isNotEmpty)
          rootKey(rootDate(task.originalDateKey, dateKey), task.originalAssignmentId ?? task.id),
    };

    for (final entry in latestReaderTasks.entries) {
      final task = entry.value.$2;
      if (task.completed || currentReaderRoots.contains(entry.key)) continue;
      final split = entry.key.split('\u0000');
      model.logs.putIfAbsent(dateKey, () => log);
      log.readingSessions.add(
        task.copyWith(
          id: '${dateKey}_carry_${split.first}_${split.last}',
          originalDateKey: split.first,
          originalAssignmentId: split.last,
        ),
      );
      currentReaderRoots.add(entry.key);
      changed = true;
    }
    for (final entry in latestHifzTasks.entries) {
      final task = entry.value.$2;
      if (task.status == 'completed' ||
          currentHifzRoots.contains(entry.key) ||
          !_isHifzCategoryScheduled(task.category, targetDate.weekday, model.studentHifzSettings)) {
        continue;
      }
      final split = entry.key.split('\u0000');
      model.logs.putIfAbsent(dateKey, () => log);
      log.hifzAssignments.add(
        task.copyWith(
          id: '${dateKey}_carry_${split.first}_${split.last}',
          originalDateKey: split.first,
          originalAssignmentId: split.last,
        ),
      );
      currentHifzRoots.add(entry.key);
      changed = true;
    }
    for (final entry in latestHafezTasks.entries) {
      final task = entry.value.$2;
      if (task.status == 'completed' ||
          currentHafezRoots.contains(entry.key) ||
          !model.hafezSettings.availableWeekdays.contains(targetDate.weekday)) {
        continue;
      }
      final split = entry.key.split('\u0000');
      model.logs.putIfAbsent(dateKey, () => log);
      log.hafezAssignments.add(
        task.copyWith(
          id: '${dateKey}_carry_${split.first}_${split.last}',
          originalDateKey: split.first,
          originalAssignmentId: split.last,
        ),
      );
      currentHafezRoots.add(entry.key);
      changed = true;
    }
    return changed;
  }

  static List<({String category, String portionId, int startPage, int endPage})>
      buildStudentDayPagePlan({
        required HifzSettings settings,
        required List<MemorizedPortion> portions,
        int? weekday,
      }) {
    final plan = <({String category, String portionId, int startPage, int endPage})>[];
    final sabaqStart = _nextUnmemorizedPage(settings.sabaqStartPage, portions);
    if ((weekday == null || settings.sabaqWeekdays.contains(weekday)) &&
        sabaqStart <= totalQuranPages) {
      final endPage =
          (sabaqStart + settings.sabaqPages - 1).clamp(sabaqStart, totalQuranPages).toInt();
      plan.add((category: 'sabaq', portionId: '', startPage: sabaqStart, endPage: endPage));
    }

    final recent = (weekday == null || settings.sabqiWeekdays.contains(weekday)
            ? portions.where((portion) => portion.status == 'recent')
            : const <MemorizedPortion>[])
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
    var sabqiPages = 0;
    for (final portion in recent) {
      final sabqiCount = plan.where((item) => item.category == 'sabqi').length;
      if (settings.sabqiRule == 'lessons' && sabqiCount >= settings.sabqiLessonCount) break;
      if (settings.sabqiRule == 'pages' && sabqiPages >= settings.sabqiPageCount) break;
      final startPage = portion.range.startPage;
      if (_overlapsPagePlan(startPage, portion.range.endPage, plan)) continue;
      final availablePages = settings.sabqiRule == 'pages'
          ? settings.sabqiPageCount - sabqiPages
          : portion.range.endPage - startPage + 1;
      final endPage =
          (startPage + availablePages - 1).clamp(startPage, portion.range.endPage).toInt();
      plan.add((
        category: 'sabqi',
        portionId: portion.id,
        startPage: startPage,
        endPage: endPage,
      ));
      sabqiPages += endPage - startPage + 1;
    }

    final eligibleManzil = (weekday == null || settings.manzilWeekdays.contains(weekday)
            ? portions.where((portion) => portion.status == 'established' || portion.status == 'reinforcement')
            : const <MemorizedPortion>[])
        .toList()
      ..sort((a, b) => a.range.startPage.compareTo(b.range.startPage));
    final manzilRange = _nextManzilRange(
      eligibleManzil,
      settings.manzilCursorPage,
      settings.manzilPages,
      plan,
    );
    if (manzilRange != null) {
      plan.add((
        category: 'manzil',
        portionId: '',
        startPage: manzilRange.$1,
        endPage: manzilRange.$2,
      ));
    }
    return plan;
  }

  Future<void> recordHifzAssessment({
    required String dateKey,
    required String assignmentId,
    required String assessment,
    required List<String> mistakes,
    required int repetitionCount,
    required String teacherFeedback,
    required bool markCompleted,
    QuranRange? actualRange,
  }) async {
    const allowedAssessments = {'perfect', 'minor', 'multiple', 'assistance', 'repeat'};
    const allowedMistakes = {
      'missedAyah',
      'wordSubstitution',
      'hesitation',
      'sequenceConfusion',
      'tajweed',
    };
    if (!allowedAssessments.contains(assessment) ||
        mistakes.any((mistake) => !allowedMistakes.contains(mistake)) ||
        repetitionCount < 0 ||
        repetitionCount > 10000) {
      throw ArgumentError('The Hifz assessment contains an invalid value.');
    }
    final model = await getPlannerData();
    final log = model.logs[dateKey];
    if (log == null) throw StateError('The selected day has no Hifz plan.');
    final index = log.hifzAssignments.indexWhere((item) => item.id == assignmentId);
    if (index < 0) throw StateError('Hifz assignment was not found.');
    final assignment = log.hifzAssignments[index];
    if (actualRange != null) {
      final surahs = await QuranDbHelper.instance.getAllSurahs();
      if (!actualRange.isValid({for (final surah in surahs) surah.id: surah.totalAyahs}) ||
          !quranRangeContains(assignment.range, actualRange) ||
          (assignment.category == 'sabaq' &&
              (actualRange.startSurahId != assignment.range.startSurahId ||
                  actualRange.startAyahNumber != assignment.range.startAyahNumber))) {
        throw ArgumentError('The actual Quran range must be valid and within the assigned range.');
      }
    }
    if (markCompleted && assessment != 'perfect' && assessment != 'minor') {
      throw ArgumentError('A weak or assisted recitation cannot be marked complete.');
    }
    final updatedStatus = markCompleted ? 'completed' : 'partial';
    log.hifzAssignments[index] = assignment.copyWith(
      status: updatedStatus,
      actualRange: actualRange,
      assessment: assessment,
      mistakes: mistakes,
      repetitionCount: repetitionCount,
      teacherFeedback: teacherFeedback.trim(),
    );

    if (markCompleted && assignment.category == 'sabaq') {
      final memorizedRange = actualRange ?? assignment.range;
      final duplicate = model.memorizedPortions.any(
        (portion) => quranRangesOverlap(portion.range, memorizedRange),
      );
      if (!duplicate) {
        model.memorizedPortions.add(
          MemorizedPortion(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            range: memorizedRange,
            status: 'recent',
            addedDate: dateKey,
          ),
        );
      }
      model.studentHifzSettings = model.studentHifzSettings.copyWith(
        sabaqStartPage: memorizedRange.endPage + 1,
      );
    } else if (markCompleted && assignment.category == 'manzil') {
      final reviewedRange = actualRange ?? assignment.range;
      model.studentHifzSettings = model.studentHifzSettings.copyWith(
        manzilCursorPage: reviewedRange.endPage >= totalQuranPages
            ? 1
            : reviewedRange.endPage + 1,
      );
    }
    await savePlannerData(model);
  }

  static int _nextUnmemorizedPage(int requestedPage, List<MemorizedPortion> portions) {
    var page = requestedPage.clamp(1, totalQuranPages + 1).toInt();
    while (page <= totalQuranPages) {
      final covering = portions.where(
        (portion) => page >= portion.range.startPage && page <= portion.range.endPage,
      );
      if (covering.isEmpty) return page;
      page = covering.map((portion) => portion.range.endPage).reduce((a, b) => a > b ? a : b) + 1;
    }
    return page;
  }

  static bool _overlapsPagePlan(
    int startPage,
    int endPage,
    List<({String category, String portionId, int startPage, int endPage})> assignments,
  ) =>
      assignments.any(
        (assignment) => startPage <= assignment.endPage && assignment.startPage <= endPage,
      );

  static bool quranRangesOverlap(QuranRange first, QuranRange second) {
    return !_pointIsAfter(
          first.startSurahId,
          first.startAyahNumber,
          second.endSurahId,
          second.endAyahNumber,
        ) &&
        !_pointIsAfter(
          second.startSurahId,
          second.startAyahNumber,
          first.endSurahId,
          first.endAyahNumber,
        );
  }

  static bool quranRangeContains(QuranRange container, QuranRange contained) =>
      !_pointIsAfter(
        container.startSurahId,
        container.startAyahNumber,
        contained.startSurahId,
        contained.startAyahNumber,
      ) &&
      !_pointIsAfter(
        contained.endSurahId,
        contained.endAyahNumber,
        container.endSurahId,
        container.endAyahNumber,
      );

  static bool _pointIsAfter(int firstSurah, int firstAyah, int secondSurah, int secondAyah) {
    final surahComparison = firstSurah.compareTo(secondSurah);
    return surahComparison > 0 || (surahComparison == 0 && firstAyah > secondAyah);
  }

  static bool isHafezWeakPortionDue(HafezWeakPortion portion, DateTime date) {
    final reviewDate = DateTime.tryParse(portion.nextReviewDate ?? '');
    if (portion.status == 'strengthened' && reviewDate == null) return false;
    final selectedDay = DateTime(date.year, date.month, date.day);
    return reviewDate == null || !reviewDate.isAfter(selectedDay);
  }

  static HifzWeeklyStats calculateHifzWeeklyStats(
    PlannerModel model, {
    required DateTime weekEnding,
  }) {
    final end = DateTime(weekEnding.year, weekEnding.month, weekEnding.day);
    final start = end.subtract(const Duration(days: 6));
    final assignments = <HifzAssignment>[];
    for (final entry in model.logs.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null || date.isBefore(start) || date.isAfter(end)) continue;
      assignments.addAll(entry.value.hifzAssignments);
    }
    return HifzWeeklyStats(
      sabaqPagesLearned: assignments
          .where((item) => item.category == 'sabaq' && item.status == 'completed')
          .fold(
            0,
            (total, item) =>
                total +
                ((item.actualRange ?? item.range).endPage -
                    (item.actualRange ?? item.range).startPage +
                    1),
          ),
      sabqiAssignments: assignments.where((item) => item.category == 'sabqi').length,
      completedSabqiAssignments: assignments
          .where((item) => item.category == 'sabqi' && item.status == 'completed')
          .length,
      manzilAssignments: assignments.where((item) => item.category == 'manzil').length,
      completedManzilAssignments: assignments
          .where((item) => item.category == 'manzil' && item.status == 'completed')
          .length,
      weakPortions: model.memorizedPortions.where((item) => item.status == 'reinforcement').length,
      assessedAssignments: assignments.where((item) => item.assessment != null).length,
      feedbackEntries: assignments.where((item) => item.teacherFeedback.trim().isNotEmpty).length,
    );
  }

  static HafezWeeklyStats calculateHafezWeeklyStats(
    PlannerModel model, {
    required DateTime weekEnding,
  }) {
    final end = DateTime(weekEnding.year, weekEnding.month, weekEnding.day);
    final start = end.subtract(const Duration(days: 6));
    final assignments = <HafezAssignment>[];
    for (final entry in model.logs.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null || date.isBefore(start) || date.isAfter(end)) continue;
      assignments.addAll(entry.value.hafezAssignments);
    }
    final completedDaur = assignments
        .where((item) => item.category == 'daur' && item.status == 'completed')
        .toList();
    return HafezWeeklyStats(
      daurAssignments: assignments.where((item) => item.category == 'daur').length,
      completedDaurAssignments: completedDaur.length,
      daurPagesCompleted: completedDaur.fold(
        0,
        (total, item) => total + item.range.endPage - item.range.startPage + 1,
      ),
      weakReviewAssignments: assignments.where((item) => item.category == 'weak').length,
      completedWeakReviews: assignments
          .where((item) => item.category == 'weak' && item.status == 'completed')
          .length,
      weakPortionsDue: model.hafezWeakPortions
          .where((item) => isHafezWeakPortionDue(item, end))
          .length,
      assessedAssignments: assignments.where((item) => item.assessment != null).length,
    );
  }

  static (int, int)? _nextManzilRange(
    List<MemorizedPortion> portions,
    int cursorPage,
    int requestedPages,
    List<({String category, String portionId, int startPage, int endPage})> assignments,
  ) {
    if (portions.isEmpty) return null;
    final startCursor = cursorPage.clamp(1, totalQuranPages).toInt();
    final ordered = [
      ...portions.where((portion) => portion.range.endPage >= startCursor),
      ...portions.where((portion) => portion.range.endPage < startCursor),
    ];
    for (final portion in ordered) {
      final start = portion.range.startPage < startCursor && portion.range.endPage >= startCursor
          ? startCursor
          : portion.range.startPage;
      if (_overlapsPagePlan(start, portion.range.endPage, assignments)) {
        continue;
      }
      final end = (start + requestedPages - 1)
          .clamp(start, portion.range.endPage)
          .toInt();
      return (start, end);
    }
    return null;
  }

  Future<QuranRange> _quranRangeForPages(int startPage, int endPage) async {
    final db = QuranDbHelper.instance;
    final start = await db.getPageInfo(startPage);
    final end = await db.getPageInfo(endPage);
    if (start == null || end == null) {
      throw StateError('Quran page references for the requested range are unavailable.');
    }
    int readInt(Map<String, dynamic> info, String key) {
      final value = info[key];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final range = QuranRange(
      startSurahId: readInt(start, 'start_surah_id'),
      startAyahNumber: readInt(start, 'start_ayah_number'),
      endSurahId: readInt(end, 'end_surah_id'),
      endAyahNumber: readInt(end, 'end_ayah_number'),
      startPage: startPage,
      endPage: endPage,
    );
    if (range.startSurahId < 1 ||
        range.startAyahNumber < 1 ||
        range.endSurahId < 1 ||
        range.endAyahNumber < 1) {
      throw StateError('Quran page references are incomplete.');
    }
    return range;
  }

  void _validateReadingSessions(List<ReadingSession> sessions) {
    if (sessions.isEmpty) {
      throw const FormatException('At least one reading session is required.');
    }
    final ids = <String>{};
    for (final session in sessions) {
      if (session.id.trim().isEmpty ||
          session.title.trim().isEmpty ||
          !RegExp(r'^\d{2}:\d{2}$').hasMatch(session.time)) {
        throw const FormatException('Reading sessions require a title and a valid time.');
      }
      final parts = session.time.split(':').map(int.parse).toList();
      if (parts[0] > 23 || parts[1] > 59 || !ids.add(session.id)) {
        throw const FormatException('Reading session times or identifiers are invalid.');
      }
    }
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

  static List<(int startPage, int endPage)> generalReaderPageRanges({
    required int startPage,
    required int targetDays,
    int? pagesPerDay,
  }) {
    if (startPage < 1 || startPage > totalQuranPages) {
      throw ArgumentError.value(startPage, 'startPage', 'Must be between 1 and 612.');
    }
    if (targetDays < 1 || targetDays > totalQuranPages) {
      throw ArgumentError.value(targetDays, 'targetDays', 'Must be between 1 and 612.');
    }
    if (pagesPerDay != null && (pagesPerDay < 1 || pagesPerDay > totalQuranPages)) {
      throw ArgumentError.value(pagesPerDay, 'pagesPerDay', 'Must be between 1 and 612.');
    }

    final remainingPages = totalQuranPages - startPage + 1;
    if (pagesPerDay != null) {
      final ranges = <(int, int)>[];
      var page = startPage;
      while (page <= totalQuranPages) {
        final endPage = (page + pagesPerDay - 1).clamp(page, totalQuranPages).toInt();
        ranges.add((page, endPage));
        page = endPage + 1;
      }
      return ranges;
    }

    final dayCount = targetDays.clamp(1, remainingPages).toInt();
    return List.generate(dayCount, (index) {
      final startOffset = (index * remainingPages) ~/ dayCount;
      final endOffset = ((index + 1) * remainingPages) ~/ dayCount;
      return (startPage + startOffset, startPage + endOffset - 1);
    });
  }

  static List<ReadingSessionAssignment> allocateReaderSessions({
    required int startPage,
    required int endPage,
    required List<ReadingSession> sessions,
    Map<String, bool> completedSessions = const {},
  }) {
    if (startPage < 1 || endPage > totalQuranPages || startPage > endPage) {
      throw ArgumentError('The reading-session page range is invalid.');
    }
    if (sessions.isEmpty) {
      throw ArgumentError.value(sessions, 'sessions', 'At least one session is required.');
    }
    final pageCount = endPage - startPage + 1;
    final usedSessionCount = sessions.length.clamp(1, pageCount).toInt();
    final basePages = pageCount ~/ usedSessionCount;
    final extraPages = pageCount % usedSessionCount;
    final assignments = <ReadingSessionAssignment>[];
    var nextPage = startPage;

    for (var index = 0; index < usedSessionCount; index++) {
      final session = sessions[index];
      final sessionPages = basePages + (index < extraPages ? 1 : 0);
      final sessionEndPage = nextPage + sessionPages - 1;
      assignments.add(
        ReadingSessionAssignment(
          id: session.id,
          sessionId: session.id,
          title: session.title,
          time: session.time,
          startPage: nextPage,
          endPage: sessionEndPage,
          completed: completedSessions[session.id] ?? false,
        ),
      );
      nextPage = sessionEndPage + 1;
    }
    return assignments;
  }

  Future<void> _generateGeneralReaderPlan({
    required PlannerModel model,
    required int targetDays,
    required int startPage,
    required DateTime startDate,
    required String goalMode,
    required int pagesPerDay,
  }) async {
    final validStartPage = startPage.clamp(1, totalQuranPages).toInt();
    final ranges = generalReaderPageRanges(
      startPage: validStartPage,
      targetDays: targetDays.clamp(1, totalQuranPages).toInt(),
      pagesPerDay: goalMode == 'pages' ? pagesPerDay.clamp(1, totalQuranPages).toInt() : null,
    );
    final validPagesPerDay = goalMode == 'pages'
        ? pagesPerDay.clamp(1, totalQuranPages).toInt()
        : ((totalQuranPages - validStartPage + 1) / ranges.length).ceil();
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final newPlanDates = {
      for (var index = 0; index < ranges.length; index++)
        TriCalendarHelper.formatDateKey(normalizedStartDate.add(Duration(days: index))),
    };
    _validateReadingSessions(model.readerSessions);

    final oldStartDate = DateTime.tryParse(model.planStartDate ?? '');
    if (oldStartDate != null) {
      final oldPlanDays = model.targetDays.clamp(1, totalQuranPages).toInt();
      for (var index = 0; index < oldPlanDays; index++) {
        final oldDate = oldStartDate.add(Duration(days: index));
        final oldKey = TriCalendarHelper.formatDateKey(oldDate);
        if (newPlanDates.contains(oldKey)) continue;
        final oldLog = model.logs[oldKey];
        if (oldLog == null || _hasReaderActivity(oldLog)) continue;
        oldLog
          ..generalTilawat = null
          ..dourPara = null
          ..pagesCount = 0
          ..readingSessions = [];
        if (oldLog.status == 'pending') oldLog.status = null;
      }
    }

    for (var index = 0; index < ranges.length; index++) {
      final date = normalizedStartDate.add(Duration(days: index));
      final dateKey = TriCalendarHelper.formatDateKey(date);
      final log = model.logs.putIfAbsent(dateKey, DayLog.new);
      if (log.status == 'completed' || (date.isBefore(todayDate) && _hasReaderActivity(log))) {
        continue;
      }

      final (firstPage, lastPage) = ranges[index];
      final pageCount = lastPage - firstPage + 1;
      final planText = _readerPageRangeText(firstPage, lastPage);
      final carriedSessions = log.readingSessions
          .where((session) => session.originalDateKey != null)
          .toList();
      final previousSessionStates = {
        for (final session in log.readingSessions)
          if (session.originalDateKey == null) session.sessionId: session.completed,
      };
      final assignedSessions = allocateReaderSessions(
        startPage: firstPage,
        endPage: lastPage,
        sessions: model.readerSessions,
        completedSessions: previousSessionStates,
      );

      log
        ..generalTilawat = planText
        ..dourPara = planText
        ..pagesCount = pageCount
        ..readingSessions = [...assignedSessions, ...carriedSessions];
      log.status ??= 'pending';
      if (dateKey == TriCalendarHelper.formatDateKey(todayDate)) {
        PlannerService.carryForwardMissedTasks(model, dateKey);
      }
    }

    model
      ..targetDays = ranges.length
      ..pagesPerDay = validPagesPerDay
      ..roadmapGoalMode = goalMode == 'pages' ? 'pages' : 'days'
      ..planStartPage = validStartPage
      ..planStartDate = TriCalendarHelper.formatDateKey(normalizedStartDate);
    await savePlannerData(model);
  }

  bool _hasReaderActivity(DayLog log) =>
      log.status == 'completed' ||
      log.status == 'partial' ||
      log.totalDayPages > 0 ||
      log.parasRead > 0 ||
      log.pagesRead > 0 ||
      (log.generalTilawat != null &&
          log.generalTilawat!.trim().isNotEmpty &&
          log.generalTilawat != log.dourPara) ||
      log.readingRanges.isNotEmpty ||
      log.readingSessions.isNotEmpty;

  String _readerPageRangeText(int startPage, int endPage) {
    final start = TriCalendarHelper.toBnNum(startPage);
    final end = TriCalendarHelper.toBnNum(endPage);
    return startPage == endPage ? 'পৃষ্ঠা $start' : 'পৃষ্ঠা $start থেকে $end';
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
    try {
      final reminderScheduled = wantsReminder
          ? await PlannerReminderService.instance.scheduleDailyReminder(model.reminderTime)
          : true;
      if (!wantsReminder) {
        await PlannerReminderService.instance.cancelDailyReminder();
      }
      model.reminderEnabled = wantsReminder && reminderScheduled;
      await savePlannerData(model);
      final hifzRemindersScheduled =
          await PlannerReminderService.instance.scheduleHifzReminders(model.studentHifzSettings);
      final readerRemindersScheduled =
          await PlannerReminderService.instance.scheduleReaderSessionReminders(model.readerSessions);
      return PlannerBackupImportResult(
        reminderScheduled:
            reminderScheduled && hifzRemindersScheduled && readerRemindersScheduled,
      );
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
    final targetDays = model.targetDays > 0 ? model.targetDays : 30;
    final planStart = model.profileMode == 'general'
        ? DateTime.tryParse(model.planStartDate ?? '')
        : null;
    final planEnd = planStart?.add(Duration(days: targetDays - 1));

    model.logs.forEach((dateKey, dayLog) {
      if (planStart != null) {
        final logDate = DateTime.tryParse(dateKey);
        if (logDate == null ||
            logDate.isBefore(DateTime(planStart.year, planStart.month, planStart.day)) ||
            logDate.isAfter(DateTime(planEnd!.year, planEnd.month, planEnd.day))) {
          return;
        }
      }
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

    final planPages = planStart == null
        ? totalQuranPages
        : (totalQuranPages - model.planStartPage.clamp(1, totalQuranPages).toInt() + 1);
    final clampedRead = totalPages.clamp(0, planPages);
    final percent = (totalPages >= planPages)
        ? 100.0
        : (clampedRead / planPages) * 100.0;
    final remainingPages = (planPages - clampedRead).clamp(0, planPages);
    final remainingParas = remainingPages / pagesPerPara.toDouble();
    final daysLeft = (targetDays - completedDaysCount).clamp(1, targetDays);
    final dailyRequired = (remainingPages > 0) ? (remainingPages / daysLeft).ceil() : 0;
    final isCompleted = totalPages >= planPages;

    return KhatamStats(
      totalPagesRead: totalPages,
      totalQuranPages: planPages,
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
    int startPage = 1,
  }) async {
    final model = await getPlannerData();
    if (mode == 'general') {
      await _generateGeneralReaderPlan(
        model: model,
        targetDays: targetDays,
        startPage: startPage,
        startDate: startDate,
        goalMode: goalMode,
        pagesPerDay: pagesPerDay,
      );
      return;
    }
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
