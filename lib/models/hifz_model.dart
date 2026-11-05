import 'quran_range.dart';

class HifzSettings {
  final int sabaqStartPage;
  final int sabaqPages;
  final String revisionMethod;
  final String sabqiRule;
  final int sabqiLessonCount;
  final int sabqiPageCount;
  final int manzilPages;
  final int manzilCursorPage;
  final bool sabaqReminderEnabled;
  final String sabaqReminderTime;
  final bool sabqiReminderEnabled;
  final String sabqiReminderTime;
  final bool manzilReminderEnabled;
  final String manzilReminderTime;
  final List<int> sabaqWeekdays;
  final List<int> sabqiWeekdays;
  final List<int> manzilWeekdays;

  const HifzSettings({
    this.sabaqStartPage = 1,
    this.sabaqPages = 1,
    this.revisionMethod = 'traditional',
    this.sabqiRule = 'lessons',
    this.sabqiLessonCount = 7,
    this.sabqiPageCount = 20,
    this.manzilPages = 20,
    this.manzilCursorPage = 1,
    this.sabaqReminderEnabled = false,
    this.sabaqReminderTime = '06:00',
    this.sabqiReminderEnabled = false,
    this.sabqiReminderTime = '15:00',
    this.manzilReminderEnabled = false,
    this.manzilReminderTime = '20:00',
    this.sabaqWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.sabqiWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.manzilWeekdays = const [1, 2, 3, 4, 5, 6, 7],
  });

  HifzSettings copyWith({
    int? sabaqStartPage,
    int? sabaqPages,
    String? revisionMethod,
    String? sabqiRule,
    int? sabqiLessonCount,
    int? sabqiPageCount,
    int? manzilPages,
    int? manzilCursorPage,
    bool? sabaqReminderEnabled,
    String? sabaqReminderTime,
    bool? sabqiReminderEnabled,
    String? sabqiReminderTime,
    bool? manzilReminderEnabled,
    String? manzilReminderTime,
    List<int>? sabaqWeekdays,
    List<int>? sabqiWeekdays,
    List<int>? manzilWeekdays,
  }) =>
      HifzSettings(
        sabaqStartPage: sabaqStartPage ?? this.sabaqStartPage,
        sabaqPages: sabaqPages ?? this.sabaqPages,
        revisionMethod: revisionMethod ?? this.revisionMethod,
        sabqiRule: sabqiRule ?? this.sabqiRule,
        sabqiLessonCount: sabqiLessonCount ?? this.sabqiLessonCount,
        sabqiPageCount: sabqiPageCount ?? this.sabqiPageCount,
        manzilPages: manzilPages ?? this.manzilPages,
        manzilCursorPage: manzilCursorPage ?? this.manzilCursorPage,
        sabaqReminderEnabled: sabaqReminderEnabled ?? this.sabaqReminderEnabled,
        sabaqReminderTime: sabaqReminderTime ?? this.sabaqReminderTime,
        sabqiReminderEnabled: sabqiReminderEnabled ?? this.sabqiReminderEnabled,
        sabqiReminderTime: sabqiReminderTime ?? this.sabqiReminderTime,
        manzilReminderEnabled: manzilReminderEnabled ?? this.manzilReminderEnabled,
        manzilReminderTime: manzilReminderTime ?? this.manzilReminderTime,
        sabaqWeekdays: sabaqWeekdays ?? this.sabaqWeekdays,
        sabqiWeekdays: sabqiWeekdays ?? this.sabqiWeekdays,
        manzilWeekdays: manzilWeekdays ?? this.manzilWeekdays,
      );

  Map<String, dynamic> toMap() => {
        'sabaqStartPage': sabaqStartPage,
        'sabaqPages': sabaqPages,
        'revisionMethod': revisionMethod,
        'sabqiRule': sabqiRule,
        'sabqiLessonCount': sabqiLessonCount,
        'sabqiPageCount': sabqiPageCount,
        'manzilPages': manzilPages,
        'manzilCursorPage': manzilCursorPage,
        'sabaqReminderEnabled': sabaqReminderEnabled,
        'sabaqReminderTime': sabaqReminderTime,
        'sabqiReminderEnabled': sabqiReminderEnabled,
        'sabqiReminderTime': sabqiReminderTime,
        'manzilReminderEnabled': manzilReminderEnabled,
        'manzilReminderTime': manzilReminderTime,
        'sabaqWeekdays': sabaqWeekdays,
        'sabqiWeekdays': sabqiWeekdays,
        'manzilWeekdays': manzilWeekdays,
      };

  factory HifzSettings.fromMap(Map<String, dynamic> map) {
    int readInt(String key, int fallback) {
      final value = map[key];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    final revisionMethod = map['revisionMethod']?.toString() ?? 'traditional';
    final sabqiRule = map['sabqiRule']?.toString() ?? 'lessons';
    String readTime(String key, String fallback) {
      final value = map[key]?.toString() ?? fallback;
      final parts = value.split(':');
      final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
      final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return fallback;
      }
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    List<int> readWeekdays(String key) {
      final raw = map[key];
      if (raw is! List) return const [1, 2, 3, 4, 5, 6, 7];
      return raw
          .map((value) => value is int ? value : int.tryParse(value.toString()))
          .whereType<int>()
          .where((day) => day >= 1 && day <= 7)
          .toSet()
          .toList()
        ..sort();
    }

    return HifzSettings(
      sabaqStartPage: readInt('sabaqStartPage', 1).clamp(1, 613).toInt(),
      sabaqPages: readInt('sabaqPages', 1).clamp(1, 612).toInt(),
      revisionMethod: const {'traditional', 'teacher', 'custom'}.contains(revisionMethod)
          ? revisionMethod
          : 'traditional',
      sabqiRule: const {'lessons', 'pages'}.contains(sabqiRule) ? sabqiRule : 'lessons',
      sabqiLessonCount: readInt('sabqiLessonCount', 7).clamp(1, 100).toInt(),
      sabqiPageCount: readInt('sabqiPageCount', 20).clamp(1, 612).toInt(),
      manzilPages: readInt('manzilPages', 20).clamp(1, 612).toInt(),
      manzilCursorPage: readInt('manzilCursorPage', 1).clamp(1, 612).toInt(),
      sabaqReminderEnabled: map['sabaqReminderEnabled'] == true,
      sabaqReminderTime: readTime('sabaqReminderTime', '06:00'),
      sabqiReminderEnabled: map['sabqiReminderEnabled'] == true,
      sabqiReminderTime: readTime('sabqiReminderTime', '15:00'),
      manzilReminderEnabled: map['manzilReminderEnabled'] == true,
      manzilReminderTime: readTime('manzilReminderTime', '20:00'),
      sabaqWeekdays: readWeekdays('sabaqWeekdays'),
      sabqiWeekdays: readWeekdays('sabqiWeekdays'),
      manzilWeekdays: readWeekdays('manzilWeekdays'),
    );
  }
}

class MemorizedPortion {
  final String id;
  final QuranRange range;
  final String status;
  final String addedDate;

  const MemorizedPortion({
    required this.id,
    required this.range,
    this.status = 'recent',
    required this.addedDate,
  });

  MemorizedPortion copyWith({String? status}) => MemorizedPortion(
        id: id,
        range: range,
        status: status ?? this.status,
        addedDate: addedDate,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'range': range.toMap(),
        'status': status,
        'addedDate': addedDate,
      };

  factory MemorizedPortion.fromMap(Map<String, dynamic> map) {
    final rawRange = map['range'];
    if (rawRange is! Map) {
      throw const FormatException('Memorized portion is missing its Quran range.');
    }
    final status = map['status']?.toString() ?? 'recent';
    return MemorizedPortion(
      id: map['id']?.toString() ?? '',
      range: QuranRange.fromMap(Map<String, dynamic>.from(rawRange)),
      status: const {'learning', 'recent', 'established', 'reinforcement'}.contains(status)
          ? status
          : 'recent',
      addedDate: map['addedDate']?.toString() ?? '',
    );
  }
}

class HifzAssignment {
  final String id;
  final String? originalDateKey;
  final String? originalAssignmentId;
  final String category;
  final String portionId;
  final QuranRange range;
  final QuranRange? actualRange;
  final String status;
  final String? assessment;
  final List<String> mistakes;
  final int repetitionCount;
  final String teacherFeedback;

  const HifzAssignment({
    required this.id,
    this.originalDateKey,
    this.originalAssignmentId,
    required this.category,
    this.portionId = '',
    required this.range,
    this.actualRange,
    this.status = 'pending',
    this.assessment,
    this.mistakes = const [],
    this.repetitionCount = 0,
    this.teacherFeedback = '',
  });

  HifzAssignment copyWith({
    String? id,
    String? originalDateKey,
    String? originalAssignmentId,
    QuranRange? range,
    String? status,
    QuranRange? actualRange,
    String? assessment,
    List<String>? mistakes,
    int? repetitionCount,
    String? teacherFeedback,
  }) =>
      HifzAssignment(
        id: id ?? this.id,
        originalDateKey: originalDateKey ?? this.originalDateKey,
        originalAssignmentId: originalAssignmentId ?? this.originalAssignmentId,
        category: category,
        portionId: portionId,
        range: range ?? this.range,
        actualRange: actualRange ?? this.actualRange,
        status: status ?? this.status,
        assessment: assessment ?? this.assessment,
        mistakes: mistakes ?? this.mistakes,
        repetitionCount: repetitionCount ?? this.repetitionCount,
        teacherFeedback: teacherFeedback ?? this.teacherFeedback,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'originalDateKey': originalDateKey,
        'originalAssignmentId': originalAssignmentId,
        'category': category,
        'portionId': portionId,
        'range': range.toMap(),
        'actualRange': actualRange?.toMap(),
        'status': status,
        'assessment': assessment,
        'mistakes': mistakes,
        'repetitionCount': repetitionCount,
        'teacherFeedback': teacherFeedback,
      };

  factory HifzAssignment.fromMap(Map<String, dynamic> map) {
    final rawRange = map['range'];
    if (rawRange is! Map) {
      throw const FormatException('Hifz assignment is missing its Quran range.');
    }
    final rawActualRange = map['actualRange'];
    final rawMistakes = map['mistakes'];
    final rawAssessment = map['assessment']?.toString();
    final rawStatus = map['status']?.toString() ?? 'pending';
    final repetition = map['repetitionCount'];
    return HifzAssignment(
      id: map['id']?.toString() ?? '',
      originalDateKey: map['originalDateKey']?.toString(),
      originalAssignmentId: map['originalAssignmentId']?.toString(),
      category: map['category']?.toString() ?? '',
      portionId: map['portionId']?.toString() ?? '',
      range: QuranRange.fromMap(Map<String, dynamic>.from(rawRange)),
      actualRange: rawActualRange is Map
          ? QuranRange.fromMap(Map<String, dynamic>.from(rawActualRange))
          : null,
      status: const {'pending', 'completed', 'partial'}.contains(rawStatus) ? rawStatus : 'pending',
      assessment: const {'perfect', 'minor', 'multiple', 'assistance', 'repeat'}.contains(rawAssessment)
          ? rawAssessment
          : null,
      mistakes: rawMistakes is List ? rawMistakes.map((item) => item.toString()).toList() : const [],
      repetitionCount: repetition is int ? repetition.clamp(0, 10000).toInt() : int.tryParse(repetition?.toString() ?? '')?.clamp(0, 10000).toInt() ?? 0,
      teacherFeedback: map['teacherFeedback']?.toString() ?? '',
    );
  }
}
