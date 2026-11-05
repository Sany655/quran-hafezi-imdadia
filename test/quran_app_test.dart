import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hafezi_imdadia/models/surah.dart';
import 'package:quran_hafezi_imdadia/models/juz.dart';
import 'package:quran_hafezi_imdadia/models/ayah.dart';
import 'package:quran_hafezi_imdadia/models/word_wbw.dart';
import 'package:quran_hafezi_imdadia/models/bookmark.dart';
import 'package:quran_hafezi_imdadia/models/hifz_model.dart';
import 'package:quran_hafezi_imdadia/models/hafez_model.dart';
import 'package:quran_hafezi_imdadia/models/planner_model.dart';
import 'package:quran_hafezi_imdadia/models/quran_range.dart';
import 'package:quran_hafezi_imdadia/services/planner_service.dart';
import 'package:quran_hafezi_imdadia/utils/tri_calendar_helper.dart';

void main() {
  group('Quran Data Models Verification Tests', () {
    test('Bookmark model mapping should parse correctly', () {
      final map = {
        'id': 1,
        'page_number': 45,
        'surah_name': 'আল-বাকারাহ',
        'juz_number': 3,
        'created_at': '2026-11-01T12:00:00Z',
      };
      final bm = Bookmark.fromMap(map);
      expect(bm.id, 1);
      expect(bm.pageNumber, 45);
      expect(bm.surahName, 'আল-বাকারাহ');
      expect(bm.juzNumber, 3);
    });
    test('Surah model mapping should parse correctly', () {
      final map = {
        'id': 1,
        'name_ar': 'الفاتحة',
        'name_en': 'Al-Fatihah',
        'name_bn': 'আল-ফাতিহা',
        'meaning_bn': 'সূচনা',
        'revelation_type': 'মাক্কী',
        'total_ayahs': 7,
        'start_page': 2,
      };

      final surah = Surah.fromMap(map);
      expect(surah.id, 1);
      expect(surah.nameBn, 'আল-ফাতিহা');
      expect(surah.startPage, 2);
      expect(surah.totalAyahs, 7);
    });

    test('Juz model mapping should parse correctly', () {
      final map = {
        'id': 1,
        'name_ar': 'الم',
        'name_en': 'Alif-Lam-Meem',
        'name_bn': 'আলিফ লাম মীম',
        'start_page': 2,
      };

      final juz = Juz.fromMap(map);
      expect(juz.id, 1);
      expect(juz.nameBn, 'আলিফ লাম মীম');
      expect(juz.startPage, 2);
    });


    test('TriCalendarHelper numeral and date calculations should be accurate', () {
      expect(TriCalendarHelper.toBnNum(12345), '১২৩৪৫');
      final date = DateTime(2026, 11, 4);
      final bn = TriCalendarHelper.getBengaliDate(date);
      expect(bn.year, 1433);
      expect(bn.monthName, 'কার্তিক');

      final hj = TriCalendarHelper.getHijriDate(date);
      expect(hj.year, 1448);
      expect(hj.monthName, 'জমাদিউল আউয়াল');

      final formatted = TriCalendarHelper.formatTriDateFull(date);
      expect(formatted, contains('নভেম্বর'));
      expect(formatted, contains('কার্তিক'));
      expect(formatted, contains('জমাদিউল আউয়াল'));
    });

    test('PlannerModel and DayLog JSON serialization works correctly', () {
      final model = PlannerModel(
        profileMode: 'general',
        hijriOffset: 0,
        roadmapGoalMode: 'pages',
        planStartDate: '2026-11-04',
        planStartPage: 12,
        carryForwardMissedTasks: true,
        readerSessions: const [
          ReadingSession(
            id: 'fajr',
            title: 'ফজরের পর',
            time: '05:30',
            reminderEnabled: true,
          ),
        ],
      );
      final dKey = '2026-11-04';
      model.logs[dKey] = DayLog(
        generalTilawat: 'পারা ১',
        status: 'completed',
        readingRanges: const [
          QuranRange(
            startSurahId: 1,
            startAyahNumber: 1,
            endSurahId: 2,
            endAyahNumber: 5,
            startPage: 1,
            endPage: 2,
          ),
        ],
        readingSessions: const [
          ReadingSessionAssignment(
            sessionId: 'fajr',
            title: 'ফজরের পর',
            time: '05:30',
            startPage: 12,
            endPage: 15,
            completed: true,
          ),
        ],
        notes: [
          PlannerNote(id: 101, page: 45, text: 'তিলাওয়াত নোট', dateKey: dKey),
        ],
      );

      final map = model.toMap();
      final restored = PlannerModel.fromMap(map);

      expect(restored.profileMode, 'general');
      expect(restored.roadmapGoalMode, 'pages');
      expect(restored.planStartDate, '2026-11-04');
      expect(restored.planStartPage, 12);
      expect(restored.carryForwardMissedTasks, isTrue);
      expect(restored.readerSessions.single.id, 'fajr');
      expect(restored.readerSessions.single.reminderEnabled, isTrue);
      expect(restored.logs[dKey]?.generalTilawat, 'পারা ১');
      expect(restored.logs[dKey]?.status, 'completed');
      expect(restored.logs[dKey]?.notes.length, 1);
      expect(restored.logs[dKey]?.notes.first.text, 'তিলাওয়াত নোট');
      expect(restored.logs[dKey]?.readingRanges.single.startSurahId, 1);
      expect(restored.logs[dKey]?.readingRanges.single.endAyahNumber, 5);
      expect(restored.logs[dKey]?.readingRanges.single.endPage, 2);
      expect(restored.logs[dKey]?.readingSessions.single.startPage, 12);
      expect(restored.logs[dKey]?.readingSessions.single.id, 'fajr');
      expect(restored.logs[dKey]?.readingSessions.single.completed, isTrue);
    });

    test('Existing planner backups receive default reading sessions', () {
      final restored = PlannerModel.fromMap({'logs': <String, dynamic>{}});
      expect(restored.readerSessions.length, 4);
      expect(restored.planStartPage, 1);
      expect(restored.studentHifzSettings.sabaqStartPage, 1);
      expect(restored.studentHifzSettings.sabaqReminderEnabled, isFalse);
      expect(restored.studentHifzSettings.sabaqReminderTime, '06:00');
      expect(restored.carryForwardMissedTasks, isFalse);
      expect(restored.memorizedPortions, isEmpty);
    });

    test('Hifz inventory, configuration, assessments, and day logs round-trip', () {
      const range = QuranRange(
        startSurahId: 2,
        startAyahNumber: 1,
        endSurahId: 2,
        endAyahNumber: 5,
        startPage: 2,
        endPage: 2,
      );
      final model = PlannerModel(
        profileMode: 'student',
        studentHifzSettings: const HifzSettings(
          sabaqStartPage: 20,
          sabaqPages: 2,
          revisionMethod: 'teacher',
          sabqiRule: 'pages',
          sabqiPageCount: 15,
          manzilPages: 10,
          manzilCursorPage: 50,
          sabaqReminderEnabled: true,
          sabaqReminderTime: '07:15',
          sabqiReminderEnabled: true,
          sabqiReminderTime: '14:30',
          manzilReminderEnabled: true,
          manzilReminderTime: '20:45',
        ),
        memorizedPortions: [
          MemorizedPortion(
            id: 'portion-1',
            range: range,
            status: 'recent',
            addedDate: '2026-11-04',
          ),
        ],
      );
      model.logs['2026-11-04'] = DayLog(
        hifzAssignments: const [
          HifzAssignment(
            id: 'assignment-1',
            category: 'sabqi',
            portionId: 'portion-1',
            range: range,
            status: 'completed',
            assessment: 'minor',
            mistakes: ['hesitation'],
            repetitionCount: 3,
            teacherFeedback: 'আবার ঝালাই করুন',
          ),
        ],
        hafezAssignments: const [
          HafezAssignment(
            id: 'daur-assignment',
            category: 'daur',
            range: range,
            status: 'completed',
            assessment: 'perfect',
            repetitionCount: 2,
          ),
        ],
      );

      final restored = PlannerModel.fromMap(model.toMap());
      expect(restored.studentHifzSettings.revisionMethod, 'teacher');
      expect(restored.studentHifzSettings.sabqiRule, 'pages');
      expect(restored.studentHifzSettings.manzilCursorPage, 50);
      expect(restored.studentHifzSettings.sabaqReminderEnabled, isTrue);
      expect(restored.studentHifzSettings.sabaqReminderTime, '07:15');
      expect(restored.studentHifzSettings.sabqiReminderTime, '14:30');
      expect(restored.studentHifzSettings.manzilReminderTime, '20:45');
      expect(restored.memorizedPortions.single.status, 'recent');
      final assignment = restored.logs['2026-11-04']!.hifzAssignments.single;
      expect(assignment.category, 'sabqi');
      expect(assignment.range.startSurahId, 2);
      expect(assignment.assessment, 'minor');
      expect(assignment.mistakes, ['hesitation']);
      expect(assignment.repetitionCount, 3);
      expect(assignment.teacherFeedback, 'আবার ঝালাই করুন');
      final daurAssignment = restored.logs['2026-11-04']!.hafezAssignments.single;
      expect(daurAssignment.category, 'daur');
      expect(daurAssignment.status, 'completed');
      expect(daurAssignment.repetitionCount, 2);
    });

    test('Missed assignments carry forward while preserving original history', () {
      const range = QuranRange(
        startSurahId: 1,
        startAyahNumber: 1,
        endSurahId: 1,
        endAyahNumber: 7,
        startPage: 1,
        endPage: 1,
      );
      final model = PlannerModel(carryForwardMissedTasks: true);
      model.logs['2026-11-03'] = DayLog(
        readingSessions: const [
          ReadingSessionAssignment(
            sessionId: 'fajr',
            title: 'ফজরের পর',
            time: '05:30',
            startPage: 1,
            endPage: 1,
          ),
        ],
      );
      model.logs['2026-11-04'] = DayLog(
        readingSessions: const [
          ReadingSessionAssignment(
            sessionId: 'fajr',
            title: 'ফজরের পর',
            time: '05:30',
            startPage: 1,
            endPage: 1,
          ),
        ],
        hifzAssignments: const [
          HifzAssignment(id: 'sabaq-1', category: 'sabaq', range: range),
        ],
        hafezAssignments: const [
          HafezAssignment(id: 'daur-1', category: 'daur', range: range),
        ],
      );

      expect(PlannerService.carryForwardMissedTasks(model, '2026-11-05'), isTrue);
      final original = model.logs['2026-11-04']!;
      final carried = model.logs['2026-11-05']!;
      expect(carried.readingSessions.length, 2);
      expect(carried.readingSessions.map((item) => item.id).toSet().length, 2);
      expect(original.readingSessions.single.completed, isFalse);
      expect(original.hifzAssignments.single.status, 'pending');
      expect(original.hafezAssignments.single.status, 'pending');
      expect(
        carried.readingSessions.map((item) => item.originalDateKey).toSet(),
        {'2026-11-03', '2026-11-04'},
      );
      expect(carried.hifzAssignments.single.originalAssignmentId, 'sabaq-1');
      expect(carried.hafezAssignments.single.originalDateKey, '2026-11-04');
      final restored = PlannerModel.fromMap(model.toMap());
      expect(restored.carryForwardMissedTasks, isTrue);
      expect(
        restored.logs['2026-11-05']!.readingSessions.map((item) => item.originalDateKey).toSet(),
        {'2026-11-03', '2026-11-04'},
      );
      expect(restored.logs['2026-11-05']!.hifzAssignments.single.originalDateKey, '2026-11-04');

      carried.readingSessions = carried.readingSessions
          .map((task) => task.copyWith(completed: true))
          .toList();
      carried.hifzAssignments[0] = carried.hifzAssignments.single.copyWith(status: 'completed');
      carried.hafezAssignments[0] = carried.hafezAssignments.single.copyWith(status: 'completed');
      expect(PlannerService.carryForwardMissedTasks(model, '2026-11-06'), isFalse);
      expect(model.logs.containsKey('2026-11-06'), isFalse);
    });

    test('Partial memorization and Daur work wait for their next available weekday', () {
      const range = QuranRange(
        startSurahId: 1,
        startAyahNumber: 1,
        endSurahId: 1,
        endAyahNumber: 7,
        startPage: 1,
        endPage: 1,
      );
      final model = PlannerModel(
        carryForwardMissedTasks: true,
        studentHifzSettings: const HifzSettings(sabaqWeekdays: [3]),
        hafezSettings: const HafezSettings(availableWeekdays: [3]),
      );
      model.logs['2026-11-02'] = DayLog(
        hifzAssignments: const [
          HifzAssignment(
            id: 'sabaq',
            category: 'sabaq',
            range: range,
            status: 'partial',
          ),
        ],
        hafezAssignments: const [
          HafezAssignment(
            id: 'daur',
            category: 'daur',
            range: range,
            status: 'partial',
          ),
        ],
      );

      expect(PlannerService.carryForwardMissedTasks(model, '2026-11-03'), isFalse);
      expect(PlannerService.carryForwardMissedTasks(model, '2026-11-04'), isTrue);
      final carried = model.logs['2026-11-04']!;
      expect(carried.hifzAssignments.single.originalAssignmentId, 'sabaq');
      expect(carried.hifzAssignments.single.status, 'partial');
      expect(carried.hafezAssignments.single.originalAssignmentId, 'daur');
      expect(carried.hafezAssignments.single.status, 'partial');
    });

    test('Hafez settings and weak inventory round-trip independently from student Hifz', () {
      const range = QuranRange(
        startSurahId: 18,
        startAyahNumber: 1,
        endSurahId: 18,
        endAyahNumber: 10,
        startPage: 293,
        endPage: 294,
      );
      final model = PlannerModel(
        profileMode: 'hafiz',
        hafezSettings: const HafezSettings(cycleDays: 15, daurPages: 41, daurCursorPage: 293),
        hafezWeakPortions: [
          HafezWeakPortion(
            id: 'weak-1',
            range: range,
            status: 'reinforcement',
            addedDate: '2026-11-01',
            nextReviewDate: '2026-11-06',
          ),
        ],
      );

      final restored = PlannerModel.fromMap(model.toMap());
      expect(restored.hafezSettings.cycleDays, 15);
      expect(restored.hafezSettings.daurPages, 41);
      expect(restored.hafezSettings.daurCursorPage, 293);
      expect(restored.hafezWeakPortions.single.status, 'reinforcement');
      expect(restored.hafezWeakPortions.single.nextReviewDate, '2026-11-06');
      expect(restored.memorizedPortions, isEmpty);
    });

    test('Hafez Daur page rotation wraps at page 612 without losing pages', () {
      expect(
        PlannerService.buildHafezDayPagePlan(
          const HafezSettings(cycleDays: 7, daurPages: 4, daurCursorPage: 610),
        ),
        [(610, 612), (1, 1)],
      );
      expect(
        PlannerService.buildHafezDayPagePlan(
          const HafezSettings(cycleDays: 30, daurPages: 20, daurCursorPage: 100),
        ),
        [(100, 119)],
      );
    });

    test('Hafez custom Daur rotation preserves range order and wraps', () {
      const settings = HafezSettings(
        daurPages: 5,
        customRotationEnabled: true,
        customRotationCursor: 2,
        customRotationRanges: [
          QuranRange(
            startSurahId: 1,
            startAyahNumber: 1,
            endSurahId: 1,
            endAyahNumber: 7,
            startPage: 10,
            endPage: 12,
          ),
          QuranRange(
            startSurahId: 2,
            startAyahNumber: 1,
            endSurahId: 2,
            endAyahNumber: 10,
            startPage: 50,
            endPage: 52,
          ),
        ],
      );

      expect(
        PlannerService.buildHafezCustomDayPagePlan(settings)
            .map((item) => (item.startPage, item.endPage))
            .toList(),
        [(12, 12), (50, 52), (10, 10)],
      );
    });

    test('Hafez weak reviews respect scheduled dates and strengthened status', () {
      const range = QuranRange(
        startSurahId: 1,
        startAyahNumber: 1,
        endSurahId: 1,
        endAyahNumber: 7,
        startPage: 1,
        endPage: 1,
      );
      final weak = HafezWeakPortion(
        id: 'weak',
        range: range,
        status: 'weak',
        addedDate: '2026-11-01',
        nextReviewDate: '2026-11-06',
      );
      final strengthened = HafezWeakPortion(
        id: 'strengthened',
        range: range,
        status: 'strengthened',
        addedDate: '2026-11-01',
        nextReviewDate: '2026-11-06',
      );
      final olderStrengthened = HafezWeakPortion(
        id: 'legacy-strengthened',
        range: range,
        status: 'strengthened',
        addedDate: '2026-11-01',
      );

      expect(PlannerService.isHafezWeakPortionDue(weak, DateTime(2026, 11, 5)), isFalse);
      expect(PlannerService.isHafezWeakPortionDue(weak, DateTime(2026, 11, 6)), isTrue);
      expect(PlannerService.isHafezWeakPortionDue(strengthened, DateTime(2026, 11, 5)), isFalse);
      expect(PlannerService.isHafezWeakPortionDue(strengthened, DateTime(2026, 11, 6)), isTrue);
      expect(PlannerService.isHafezWeakPortionDue(olderStrengthened, DateTime(2026, 11, 6)), isFalse);
    });

    test('Weekly Hifz and Daur analytics count only recent completed activity', () {
      const range = QuranRange(
        startSurahId: 2,
        startAyahNumber: 1,
        endSurahId: 2,
        endAyahNumber: 5,
        startPage: 2,
        endPage: 4,
      );
      final model = PlannerModel(
        profileMode: 'student',
        memorizedPortions: [
          MemorizedPortion(
            id: 'weak-student',
            range: range,
            status: 'reinforcement',
            addedDate: '2026-11-02',
          ),
        ],
        hafezWeakPortions: [
          HafezWeakPortion(
            id: 'weak-hafez',
            range: range,
            status: 'weak',
            addedDate: '2026-11-02',
            nextReviewDate: '2026-11-04',
          ),
        ],
      );
      model.logs['2026-11-04'] = DayLog(
        hifzAssignments: const [
          HifzAssignment(
            id: 'sabaq',
            category: 'sabaq',
            range: range,
            actualRange: QuranRange(
              startSurahId: 2,
              startAyahNumber: 1,
              endSurahId: 2,
              endAyahNumber: 5,
              startPage: 2,
              endPage: 3,
            ),
            status: 'completed',
            assessment: 'perfect',
            teacherFeedback: 'ভালো',
          ),
          HifzAssignment(
            id: 'sabqi',
            category: 'sabqi',
            range: range,
            status: 'partial',
            assessment: 'minor',
          ),
          HifzAssignment(id: 'manzil', category: 'manzil', range: range),
        ],
        hafezAssignments: const [
          HafezAssignment(id: 'daur-done', category: 'daur', range: range, status: 'completed'),
          HafezAssignment(id: 'weak-done', category: 'weak', range: range, status: 'completed'),
        ],
      );
      model.logs['2026-10-28'] = DayLog(
        hifzAssignments: const [
          HifzAssignment(
            id: 'old-sabaq',
            category: 'sabaq',
            range: range,
            status: 'completed',
          ),
        ],
      );

      final studentStats = PlannerService.calculateHifzWeeklyStats(
        model,
        weekEnding: DateTime(2026, 11, 5),
      );
      expect(studentStats.sabaqPagesLearned, 2);
      expect(studentStats.sabqiAssignments, 1);
      expect(studentStats.completedSabqiAssignments, 0);
      expect(studentStats.manzilAssignments, 1);
      expect(studentStats.weakPortions, 1);
      expect(studentStats.assessedAssignments, 2);
      expect(studentStats.feedbackEntries, 1);

      final hafezStats = PlannerService.calculateHafezWeeklyStats(
        model,
        weekEnding: DateTime(2026, 11, 5),
      );
      expect(hafezStats.daurAssignments, 1);
      expect(hafezStats.completedDaurAssignments, 1);
      expect(hafezStats.daurPagesCompleted, 3);
      expect(hafezStats.weakReviewAssignments, 1);
      expect(hafezStats.completedWeakReviews, 1);
      expect(hafezStats.weakPortionsDue, 1);
      expect(hafezStats.assessedAssignments, 0);
    });

    test('Invalid Hifz enum values from older or edited backups are normalized', () {
      final settings = HifzSettings.fromMap({
        'revisionMethod': 'unknown',
        'sabqiRule': 'unknown',
        'sabaqStartPage': 999,
      });
      final portion = MemorizedPortion.fromMap({
        'id': 'portion',
        'range': const QuranRange(
          startSurahId: 1,
          startAyahNumber: 1,
          endSurahId: 1,
          endAyahNumber: 7,
          startPage: 1,
          endPage: 1,
        ).toMap(),
        'status': 'unknown',
      });
      final assignment = HifzAssignment.fromMap({
        'id': 'task',
        'category': 'sabqi',
        'range': const QuranRange(
          startSurahId: 1,
          startAyahNumber: 1,
          endSurahId: 1,
          endAyahNumber: 7,
          startPage: 1,
          endPage: 1,
        ).toMap(),
        'assessment': 'unknown',
        'status': 'unknown',
      });

      expect(settings.revisionMethod, 'traditional');
      expect(settings.sabqiRule, 'lessons');
      expect(settings.sabaqStartPage, 613);
      expect(portion.status, 'recent');
      expect(assignment.assessment, isNull);
      expect(assignment.status, 'pending');
    });

    test('Student Hifz planning derives all three layers from the inventory without overlap', () {
      const portions = [
        MemorizedPortion(
          id: 'recent-1',
          range: QuranRange(
            startSurahId: 1,
            startAyahNumber: 1,
            endSurahId: 1,
            endAyahNumber: 7,
            startPage: 1,
            endPage: 2,
          ),
          status: 'recent',
          addedDate: '2026-11-03',
        ),
        MemorizedPortion(
          id: 'recent-2',
          range: QuranRange(
            startSurahId: 2,
            startAyahNumber: 1,
            endSurahId: 2,
            endAyahNumber: 20,
            startPage: 6,
            endPage: 7,
          ),
          status: 'recent',
          addedDate: '2026-11-04',
        ),
        MemorizedPortion(
          id: 'old',
          range: QuranRange(
            startSurahId: 2,
            startAyahNumber: 21,
            endSurahId: 2,
            endAyahNumber: 100,
            startPage: 20,
            endPage: 40,
          ),
          status: 'established',
          addedDate: '2026-10-01',
        ),
      ];

      final plan = PlannerService.buildStudentDayPagePlan(
        settings: const HifzSettings(
          sabaqStartPage: 4,
          sabaqPages: 2,
          sabqiRule: 'pages',
          sabqiPageCount: 3,
          manzilPages: 10,
          manzilCursorPage: 20,
        ),
        portions: portions,
      );

      expect(
        plan.map((item) => (item.category, item.startPage, item.endPage)).toList(),
        [
          ('sabaq', 4, 5),
          ('sabqi', 6, 7),
          ('sabqi', 1, 1),
          ('manzil', 20, 29),
        ],
      );
      for (var first = 0; first < plan.length; first++) {
        for (var second = first + 1; second < plan.length; second++) {
          expect(
            plan[first].endPage < plan[second].startPage ||
                plan[second].endPage < plan[first].startPage,
            isTrue,
          );
        }
      }
    });

    test('Student Hifz planning only includes categories on selected weekdays', () {
      const portions = [
        MemorizedPortion(
          id: 'recent',
          range: QuranRange(
            startSurahId: 2,
            startAyahNumber: 1,
            endSurahId: 2,
            endAyahNumber: 20,
            startPage: 10,
            endPage: 11,
          ),
          status: 'recent',
          addedDate: '2026-11-01',
        ),
        MemorizedPortion(
          id: 'established',
          range: QuranRange(
            startSurahId: 3,
            startAyahNumber: 1,
            endSurahId: 3,
            endAyahNumber: 20,
            startPage: 30,
            endPage: 31,
          ),
          status: 'established',
          addedDate: '2026-10-01',
        ),
      ];
      const settings = HifzSettings(
        sabaqStartPage: 100,
        sabaqWeekdays: [2],
        sabqiWeekdays: [3],
        manzilWeekdays: [4],
      );

      expect(
        PlannerService.buildStudentDayPagePlan(
          settings: settings,
          portions: portions,
          weekday: 1,
        ),
        isEmpty,
      );
      expect(
        PlannerService.buildStudentDayPagePlan(
          settings: settings,
          portions: portions,
          weekday: 2,
        ).map((item) => item.category),
        ['sabaq'],
      );
      expect(
        PlannerService.buildStudentDayPagePlan(
          settings: settings,
          portions: portions,
          weekday: 3,
        ).map((item) => item.category),
        ['sabqi'],
      );
      expect(
        PlannerService.buildStudentDayPagePlan(
          settings: settings,
          portions: portions,
          weekday: 4,
        ).map((item) => item.category),
        ['manzil'],
      );
    });

    test('Sabaq starts beyond existing memorized pages and ends at Mushaf boundary', () {
      final plan = PlannerService.buildStudentDayPagePlan(
        settings: const HifzSettings(sabaqStartPage: 3, sabaqPages: 20),
        portions: const [
          MemorizedPortion(
            id: 'known',
            range: QuranRange(
              startSurahId: 1,
              startAyahNumber: 1,
              endSurahId: 2,
              endAyahNumber: 5,
              startPage: 1,
              endPage: 4,
            ),
            status: 'established',
            addedDate: '2026-11-01',
          ),
        ],
      );

      final sabaq = plan.firstWhere((item) => item.category == 'sabaq');
      expect(sabaq.category, 'sabaq');
      expect((sabaq.startPage, sabaq.endPage), (5, 24));
      final finished = PlannerService.buildStudentDayPagePlan(
        settings: const HifzSettings(sabaqStartPage: 613),
        portions: const [],
      );
      expect(finished, isEmpty);
    });

    test('Quran ranges reject invalid references and reversed boundaries', () {
      const valid = QuranRange(
        startSurahId: 2,
        startAyahNumber: 3,
        endSurahId: 2,
        endAyahNumber: 5,
        startPage: 2,
        endPage: 3,
      );
      expect(valid.isValid({2: 286}), isTrue);
      expect(valid.isValid({2: 4}), isFalse);

      const reversed = QuranRange(
        startSurahId: 3,
        startAyahNumber: 1,
        endSurahId: 2,
        endAyahNumber: 286,
        startPage: 10,
        endPage: 11,
      );
      expect(reversed.isValid({2: 286, 3: 200}), isFalse);
    });

    test('Memorized inventory overlap uses Ayah ranges rather than shared page numbers', () {
      const first = QuranRange(
        startSurahId: 2,
        startAyahNumber: 1,
        endSurahId: 2,
        endAyahNumber: 4,
        startPage: 2,
        endPage: 2,
      );
      const adjacent = QuranRange(
        startSurahId: 2,
        startAyahNumber: 5,
        endSurahId: 2,
        endAyahNumber: 9,
        startPage: 2,
        endPage: 2,
      );
      const intersecting = QuranRange(
        startSurahId: 2,
        startAyahNumber: 4,
        endSurahId: 2,
        endAyahNumber: 8,
        startPage: 2,
        endPage: 2,
      );

      expect(PlannerService.quranRangesOverlap(first, adjacent), isFalse);
      expect(PlannerService.quranRangesOverlap(first, intersecting), isTrue);
      expect(PlannerService.quranRangeContains(first, adjacent), isFalse);
      expect(PlannerService.quranRangeContains(intersecting, first), isFalse);
    });

    test('General reader plans cover only the remaining pages without wrapping', () {
      final durationPlan = PlannerService.generalReaderPageRanges(
        startPage: 500,
        targetDays: 5,
      );
      expect(durationPlan.length, 5);
      expect(durationPlan.first.$1, 500);
      expect(durationPlan.last.$2, 612);
      for (var index = 1; index < durationPlan.length; index++) {
        expect(durationPlan[index].$1, durationPlan[index - 1].$2 + 1);
      }

      final capacityPlan = PlannerService.generalReaderPageRanges(
        startPage: 600,
        targetDays: 1,
        pagesPerDay: 20,
      );
      expect(capacityPlan, [(600, 612)]);
    });

    test('Daily reading sessions divide assigned pages without gaps or overlap', () {
      const sessions = [
        ReadingSession(id: 'fajr', title: 'ফজরের পর', time: '05:30'),
        ReadingSession(id: 'dhuhr', title: 'যোহরের পর', time: '13:30'),
        ReadingSession(id: 'isha', title: 'ইশার পর', time: '20:30'),
      ];
      final assignments = PlannerService.allocateReaderSessions(
        startPage: 21,
        endPage: 25,
        sessions: sessions,
        completedSessions: const {'dhuhr': true},
      );
      expect(assignments.map((item) => (item.startPage, item.endPage)).toList(), [
        (21, 22),
        (23, 24),
        (25, 25),
      ]);
      expect(assignments[1].completed, isTrue);
    });

    test('Khatam stats use only the active reader plan and its selected start page', () {
      final model = PlannerModel(
        profileMode: 'general',
        targetDays: 2,
        planStartDate: '2026-11-04',
        planStartPage: 500,
      );
      model.logs['2026-11-03'] = DayLog(pagesRead: 100, status: 'completed');
      model.logs['2026-11-04'] = DayLog(pagesRead: 20, status: 'completed');

      final stats = PlannerService.instance.calculateKhatamStats(model);
      expect(stats.totalPagesRead, 20);
      expect(stats.totalQuranPages, 113);
      expect(stats.remainingPages, 93);
      expect(stats.completedDays, 1);
    });

    test('Integer-based tilawat tracking and KhatamStats calculation work accurately', () {
      final model = PlannerModel(profileMode: 'general', hijriOffset: 0, targetDays: 5);

      // Day 1: 10 paras (200 pages)
      model.logs['2026-11-01'] = DayLog(
        parasRead: 10,
        pagesRead: 0,
        status: 'completed',
      );
      expect(model.logs['2026-11-01']!.totalDayPages, 200);

      // Day 2: 0 paras, 5 pages
      model.logs['2026-11-02'] = DayLog(
        parasRead: 0,
        pagesRead: 5,
        status: 'completed',
      );
      expect(model.logs['2026-11-02']!.totalDayPages, 5);

      // Verify serialization of integer fields
      final map = model.toMap();
      final restored = PlannerModel.fromMap(map);
      expect(restored.logs['2026-11-01']?.parasRead, 10);
      expect(restored.logs['2026-11-01']?.pagesRead, 0);
      expect(restored.logs['2026-11-01']?.totalDayPages, 200);

      expect(restored.logs['2026-11-02']?.parasRead, 0);
      expect(restored.logs['2026-11-02']?.pagesRead, 5);
      expect(restored.logs['2026-11-02']?.totalDayPages, 5);

      // Calculate KhatamStats
      final stats = PlannerService.instance.calculateKhatamStats(restored);
      expect(stats.totalPagesRead, 205);
      expect(stats.totalQuranPages, 612);
      expect(stats.remainingPages, 407);
      expect(stats.completedDays, 2);
      expect(stats.targetDays, 5);
      expect(stats.isCompleted, false);

      // (205 / 612) * 100 = ~33.496%
      expect(stats.percent, closeTo(33.496, 0.01));

      // daysLeft = 5 - 2 = 3. dailyRequired = ceil(407 / 3) = 136 pages/day
      expect(stats.dailyRequiredPages, 136);
    });

    test('Hafiz day ranges cover a full cycle without overlap', () {
      for (final cycleDays in [7, 15, 30]) {
        final coveredParas = <int>[];
        for (var day = 0; day < cycleDays; day++) {
          final (start, end) = PlannerService.hafizParaRangeForDay(
            dayIndex: day,
            targetDays: cycleDays,
            startPara: 27,
          );
          var para = start;
          while (true) {
            coveredParas.add(para);
            if (para == end) break;
            para = para % 30 + 1;
          }
        }

        expect(coveredParas.length, 30);
        expect(coveredParas.toSet().length, 30);
        expect(coveredParas.toSet(), Set<int>.from(List.generate(30, (i) => i + 1)));
      }
    });

    test('Ayah and WordWbw relationships should attach properly', () {
      final ayah = Ayah(
        id: 1,
        surahId: 1,
        ayahNumber: 1,
        verseKey: '1:1',
        textIndopak: 'بِسۡمِ اللهِ الرَّحۡمٰنِ الرَّحِيۡمِ',
        textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        translationTaisirul: '(আরম্ভ করছি) পরম করুণাময় অসীম দয়াময় আল্লাহর নামে।',
        words: [
          WordWbw(
            id: 1,
            surahId: 1,
            ayahNumber: 1,
            position: 1,
            textArabic: 'بِسۡمِ',
            meaningBn: 'নামে',
          ),
          WordWbw(
            id: 2,
            surahId: 1,
            ayahNumber: 1,
            position: 2,
            textArabic: 'اللهِ',
            meaningBn: 'আল্লাহ (র)',
          ),
        ],
      );

      expect(ayah.ayahNumber, 1);
      ayah.surahNameBn = 'আল-ফাতিহা';
      expect(ayah.surahNameBn, 'আল-ফাতিহা');
      expect(ayah.words.length, 2);
      expect(ayah.words.first.meaningBn, 'নামে');
      expect(ayah.translationTaisirul, contains('আল্লাহর নামে'));
    });
  });
}
