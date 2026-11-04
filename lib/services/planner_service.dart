import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/planner_model.dart';
import '../utils/tri_calendar_helper.dart';

class PlannerService {
  static final PlannerService instance = PlannerService._internal();
  PlannerService._internal();

  PlannerModel? _cachedModel;

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/planner_v3.json');
  }

  Future<PlannerModel> getPlannerData() async {
    if (_cachedModel != null) return _cachedModel!;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = json.decode(content);
          if (data is Map<String, dynamic>) {
            _cachedModel = PlannerModel.fromMap(data);
            return _cachedModel!;
          }
        }
      }
    } catch (e) {
      // Fallback on clean model
    }
    _cachedModel = PlannerModel(profileMode: 'general', hijriOffset: 0);
    return _cachedModel!;
  }

  Future<void> savePlannerData(PlannerModel model) async {
    _cachedModel = model;
    try {
      final file = await _getStorageFile();
      await file.writeAsString(json.encode(model.toMap()));
    } catch (e) {
      // ignore
    }
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

  Future<void> setReminderSettings({required bool enabled, required String time}) async {
    final model = await getPlannerData();
    model.reminderEnabled = enabled;
    model.reminderTime = time;
    await savePlannerData(model);
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
    await savePlannerData(model);
  }

  Future<String> exportBackup() async {
    final model = await getPlannerData();
    return json.encode(model.toMap());
  }

  Future<bool> importBackup(String jsonStr) async {
    try {
      final data = json.decode(jsonStr);
      if (data is Map<String, dynamic>) {
        final model = PlannerModel.fromMap(data);
        await savePlannerData(model);
        return true;
      }
    } catch (e) {
      // invalid json
    }
    return false;
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

  Future<void> generatePlan({
    required String mode,
    required int targetDays,
    required int startPara,
    required DateTime startDate,
  }) async {
    final model = await getPlannerData();
    model.targetDays = targetDays;

    if (mode == 'general') {
      int currPara = startPara;
      DateTime d = DateTime(startDate.year, startDate.month, startDate.day);

      for (int i = 0; i < targetDays; i++) {
        final dKey = TriCalendarHelper.formatDateKey(d);
        if (!model.logs.containsKey(dKey)) {
          model.logs[dKey] = DayLog();
        }

        String planText = '';
        int pCount = 20;
        if (targetDays == 30) {
          final p1 = ((currPara - 1) % 30) + 1;
          planText = 'পারা ${TriCalendarHelper.toBnNum(p1)} (প্রতিদিন ১ পারা)';
          pCount = 20;
          currPara += 1;
        } else if (targetDays == 60) {
          final p1 = (((i ~/ 2) + startPara - 1) % 30) + 1;
          final part = (i % 2 == 0) ? '১ম অর্ধেক (১০ পৃষ্ঠা)' : '২য় অর্ধেক (১০ পৃষ্ঠা)';
          planText = 'পারা ${TriCalendarHelper.toBnNum(p1)} ($part)';
          pCount = 10;
        } else if (targetDays == 90) {
          final pg1 = ((i * 7) % 612) + 1;
          final pg2 = (pg1 + 6 > 612) ? 612 : pg1 + 6;
          planText = 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(pg1)} থেকে ${TriCalendarHelper.toBnNum(pg2)}';
          pCount = 7;
        } else if (targetDays == 120) {
          final pg1 = ((i * 5) % 612) + 1;
          final pg2 = (pg1 + 4 > 612) ? 612 : pg1 + 4;
          planText = 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(pg1)} থেকে ${TriCalendarHelper.toBnNum(pg2)}';
          pCount = 5;
        } else if (targetDays == 365) {
          final pg1 = (i * 1.67).floor() + 1;
          final pg2 = (((i + 1) * 1.67).floor() > 612) ? 612 : ((i + 1) * 1.67).floor();
          planText = (pg1 == pg2)
              ? 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(pg1)}'
              : 'পৃষ্ঠা ${TriCalendarHelper.toBnNum(pg1)} - ${TriCalendarHelper.toBnNum(pg2)}';
          pCount = 2;
        } else {
          final p1 = ((currPara - 1) % 30) + 1;
          planText = 'পারা ${TriCalendarHelper.toBnNum(p1)}';
          pCount = 20;
          currPara += 1;
        }

        model.logs[dKey]!.generalTilawat = planText;
        model.logs[dKey]!.dourPara = planText;
        model.logs[dKey]!.pagesCount = pCount;
        model.logs[dKey]!.status ??= 'pending';

        d = d.add(const Duration(days: 1));
      }
    } else {
      // Hafiz and Student Dour cycle
      int currPara = startPara;
      DateTime d = DateTime(startDate.year, startDate.month, startDate.day);

      for (int i = 0; i < targetDays; i++) {
        final dKey = TriCalendarHelper.formatDateKey(d);
        if (!model.logs.containsKey(dKey)) {
          model.logs[dKey] = DayLog();
        }

        String paraText = '';
        if (targetDays == 7) {
          final p1 = ((currPara - 1) % 30) + 1;
          final p4 = ((currPara + 3) % 30) + 1;
          paraText = 'পারা ${TriCalendarHelper.toBnNum(p1)} থেকে ${TriCalendarHelper.toBnNum(p4)} (৪-৫ পারা)';
          currPara += 4;
        } else if (targetDays == 10) {
          final p1 = ((currPara - 1) % 30) + 1;
          final p2 = (currPara % 30) + 1;
          final p3 = ((currPara + 1) % 30) + 1;
          paraText = 'পারা ${TriCalendarHelper.toBnNum(p1)}, ${TriCalendarHelper.toBnNum(p2)} ও ${TriCalendarHelper.toBnNum(p3)}';
          currPara += 3;
        } else if (targetDays == 15) {
          final p1 = ((currPara - 1) % 30) + 1;
          final p2 = (currPara % 30) + 1;
          paraText = 'পারা ${TriCalendarHelper.toBnNum(p1)} ও ${TriCalendarHelper.toBnNum(p2)}';
          currPara += 2;
        } else if (targetDays == 20) {
          final p1 = ((currPara - 1) % 30) + 1;
          paraText = (i % 2 == 0) ? 'পারা ${TriCalendarHelper.toBnNum(p1)} (১ম অংশ)' : 'পারা ${TriCalendarHelper.toBnNum(p1)} (২য় অংশ)';
          if (i % 2 == 1) currPara += 1;
        } else {
          final p1 = ((currPara - 1) % 30) + 1;
          paraText = 'পারা ${TriCalendarHelper.toBnNum(p1)}';
          currPara += 1;
        }

        model.logs[dKey]!.dourPara = paraText;
        model.logs[dKey]!.status ??= 'pending';

        d = d.add(const Duration(days: 1));
      }
    }

    await savePlannerData(model);
  }
}
