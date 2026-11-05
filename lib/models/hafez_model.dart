import 'quran_range.dart';

class HafezSettings {
  final int cycleDays;
  final int daurPages;
  final int daurCursorPage;
  final List<int> availableWeekdays;
  final bool customRotationEnabled;
  final List<QuranRange> customRotationRanges;
  final int customRotationCursor;

  const HafezSettings({
    this.cycleDays = 30,
    this.daurPages = 21,
    this.daurCursorPage = 1,
    this.availableWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.customRotationEnabled = false,
    this.customRotationRanges = const [],
    this.customRotationCursor = 0,
  });

  HafezSettings copyWith({
    int? cycleDays,
    int? daurPages,
    int? daurCursorPage,
    List<int>? availableWeekdays,
    bool? customRotationEnabled,
    List<QuranRange>? customRotationRanges,
    int? customRotationCursor,
  }) =>
      HafezSettings(
        cycleDays: cycleDays ?? this.cycleDays,
        daurPages: daurPages ?? this.daurPages,
        daurCursorPage: daurCursorPage ?? this.daurCursorPage,
        availableWeekdays: availableWeekdays ?? this.availableWeekdays,
        customRotationEnabled: customRotationEnabled ?? this.customRotationEnabled,
        customRotationRanges: customRotationRanges ?? this.customRotationRanges,
        customRotationCursor: customRotationCursor ?? this.customRotationCursor,
      );

  Map<String, dynamic> toMap() => {
        'cycleDays': cycleDays,
        'daurPages': daurPages,
        'daurCursorPage': daurCursorPage,
        'availableWeekdays': availableWeekdays,
        'customRotationEnabled': customRotationEnabled,
        'customRotationRanges': customRotationRanges.map((range) => range.toMap()).toList(),
        'customRotationCursor': customRotationCursor,
      };

  factory HafezSettings.fromMap(Map<String, dynamic> map) {
    int readInt(String key, int fallback) {
      final value = map[key];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    List<int> readWeekdays() {
      final raw = map['availableWeekdays'];
      if (raw is! List) return const [1, 2, 3, 4, 5, 6, 7];
      return raw
          .map((value) => value is int ? value : int.tryParse(value.toString()))
          .whereType<int>()
          .where((day) => day >= 1 && day <= 7)
          .toSet()
          .toList()
        ..sort();
    }

    final ranges = <QuranRange>[];
    final rawRanges = map['customRotationRanges'];
    if (rawRanges is List) {
      for (final item in rawRanges) {
        if (item is Map) {
          ranges.add(QuranRange.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return HafezSettings(
      cycleDays: readInt('cycleDays', 30).clamp(1, 365).toInt(),
      daurPages: readInt('daurPages', 21).clamp(1, 612).toInt(),
      daurCursorPage: readInt('daurCursorPage', 1).clamp(1, 612).toInt(),
      availableWeekdays: readWeekdays(),
      customRotationEnabled: map['customRotationEnabled'] == true,
      customRotationRanges: ranges,
      customRotationCursor: readInt('customRotationCursor', 0).clamp(0, 1000000).toInt(),
    );
  }
}

class HafezWeakPortion {
  final String id;
  final QuranRange range;
  final String status;
  final String addedDate;
  final String? nextReviewDate;
  final String? lastReviewedDate;

  const HafezWeakPortion({
    required this.id,
    required this.range,
    this.status = 'weak',
    required this.addedDate,
    this.nextReviewDate,
    this.lastReviewedDate,
  });

  HafezWeakPortion copyWith({
    String? status,
    String? nextReviewDate,
    String? lastReviewedDate,
  }) => HafezWeakPortion(
        id: id,
        range: range,
        status: status ?? this.status,
        addedDate: addedDate,
        nextReviewDate: nextReviewDate ?? this.nextReviewDate,
        lastReviewedDate: lastReviewedDate ?? this.lastReviewedDate,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'range': range.toMap(),
        'status': status,
        'addedDate': addedDate,
        'nextReviewDate': nextReviewDate,
        'lastReviewedDate': lastReviewedDate,
      };

  factory HafezWeakPortion.fromMap(Map<String, dynamic> map) {
    final rawRange = map['range'];
    if (rawRange is! Map) {
      throw const FormatException('Weak portion is missing its Quran range.');
    }
    final status = map['status']?.toString() ?? 'weak';
    return HafezWeakPortion(
      id: map['id']?.toString() ?? '',
      range: QuranRange.fromMap(Map<String, dynamic>.from(rawRange)),
      status: const {'weak', 'reinforcement', 'strengthened'}.contains(status) ? status : 'weak',
      addedDate: map['addedDate']?.toString() ?? '',
      nextReviewDate: map['nextReviewDate']?.toString(),
      lastReviewedDate: map['lastReviewedDate']?.toString(),
    );
  }
}

class HafezAssignment {
  final String id;
  final String? originalDateKey;
  final String? originalAssignmentId;
  final String category;
  final String weakPortionId;
  final QuranRange range;
  final String status;
  final String? assessment;
  final List<String> mistakes;
  final int repetitionCount;
  final String teacherFeedback;

  const HafezAssignment({
    required this.id,
    this.originalDateKey,
    this.originalAssignmentId,
    required this.category,
    this.weakPortionId = '',
    required this.range,
    this.status = 'pending',
    this.assessment,
    this.mistakes = const [],
    this.repetitionCount = 0,
    this.teacherFeedback = '',
  });

  HafezAssignment copyWith({
    String? id,
    String? originalDateKey,
    String? originalAssignmentId,
    String? status,
    String? assessment,
    List<String>? mistakes,
    int? repetitionCount,
    String? teacherFeedback,
  }) =>
      HafezAssignment(
        id: id ?? this.id,
        originalDateKey: originalDateKey ?? this.originalDateKey,
        originalAssignmentId: originalAssignmentId ?? this.originalAssignmentId,
        category: category,
        weakPortionId: weakPortionId,
        range: range,
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
        'weakPortionId': weakPortionId,
        'range': range.toMap(),
        'status': status,
        'assessment': assessment,
        'mistakes': mistakes,
        'repetitionCount': repetitionCount,
        'teacherFeedback': teacherFeedback,
      };

  factory HafezAssignment.fromMap(Map<String, dynamic> map) {
    final rawRange = map['range'];
    if (rawRange is! Map) {
      throw const FormatException('Daur assignment is missing its Quran range.');
    }
    final rawStatus = map['status']?.toString() ?? 'pending';
    final rawAssessment = map['assessment']?.toString();
    final rawRepetitions = map['repetitionCount'];
    final rawMistakes = map['mistakes'];
    return HafezAssignment(
      id: map['id']?.toString() ?? '',
      originalDateKey: map['originalDateKey']?.toString(),
      originalAssignmentId: map['originalAssignmentId']?.toString(),
      category: map['category']?.toString() ?? '',
      weakPortionId: map['weakPortionId']?.toString() ?? '',
      range: QuranRange.fromMap(Map<String, dynamic>.from(rawRange)),
      status: const {'pending', 'completed', 'partial'}.contains(rawStatus) ? rawStatus : 'pending',
      assessment: const {'perfect', 'minor', 'multiple', 'assistance', 'repeat'}.contains(rawAssessment)
          ? rawAssessment
          : null,
      mistakes: rawMistakes is List ? rawMistakes.map((item) => item.toString()).toList() : const [],
      repetitionCount: rawRepetitions is int
          ? rawRepetitions.clamp(0, 10000).toInt()
          : int.tryParse(rawRepetitions?.toString() ?? '')?.clamp(0, 10000).toInt() ?? 0,
      teacherFeedback: map['teacherFeedback']?.toString() ?? '',
    );
  }
}
