import 'quran_range.dart';
import 'hifz_model.dart';
import 'hafez_model.dart';

class ReadingSession {
  final String id;
  final String title;
  final String time;
  final bool reminderEnabled;

  const ReadingSession({
    required this.id,
    required this.title,
    required this.time,
    this.reminderEnabled = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'time': time,
        'reminderEnabled': reminderEnabled,
      };

  factory ReadingSession.fromMap(Map<String, dynamic> map) => ReadingSession(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        time: map['time']?.toString() ?? '06:00',
        reminderEnabled: map['reminderEnabled'] == true,
      );

  static const defaults = [
    ReadingSession(id: 'fajr', title: 'ফজরের পর', time: '05:30'),
    ReadingSession(id: 'dhuhr', title: 'যোহরের পর', time: '13:30'),
    ReadingSession(id: 'asr', title: 'আসরের পর', time: '16:30'),
    ReadingSession(id: 'isha', title: 'ইশার পর', time: '20:30'),
  ];
}

class ReadingSessionAssignment {
  final String id;
  final String sessionId;
  final String title;
  final String time;
  final int startPage;
  final int endPage;
  final bool completed;
  final String? originalDateKey;
  final String? originalAssignmentId;

  const ReadingSessionAssignment({
    String? id,
    required this.sessionId,
    required this.title,
    required this.time,
    required this.startPage,
    required this.endPage,
    this.completed = false,
    this.originalDateKey,
    this.originalAssignmentId,
  }) : id = id ?? sessionId;

  ReadingSessionAssignment copyWith({
    String? id,
    bool? completed,
    String? originalDateKey,
    String? originalAssignmentId,
  }) =>
      ReadingSessionAssignment(
        id: id ?? this.id,
        sessionId: sessionId,
        title: title,
        time: time,
        startPage: startPage,
        endPage: endPage,
        completed: completed ?? this.completed,
        originalDateKey: originalDateKey ?? this.originalDateKey,
        originalAssignmentId: originalAssignmentId ?? this.originalAssignmentId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'title': title,
        'time': time,
        'startPage': startPage,
        'endPage': endPage,
        'completed': completed,
        'originalDateKey': originalDateKey,
        'originalAssignmentId': originalAssignmentId,
      };

  factory ReadingSessionAssignment.fromMap(Map<String, dynamic> map) {
    int readInt(String key) {
      final value = map[key];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ReadingSessionAssignment(
      id: map['id']?.toString() ?? map['sessionId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      startPage: readInt('startPage'),
      endPage: readInt('endPage'),
      completed: map['completed'] == true,
      originalDateKey: map['originalDateKey']?.toString(),
      originalAssignmentId: map['originalAssignmentId']?.toString(),
    );
  }
}

class PlannerNote {
  final int id;
  final int page;
  final int? line;
  final String text;
  final String dateKey;

  PlannerNote({
    required this.id,
    required this.page,
    this.line,
    required this.text,
    required this.dateKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'page': page,
      'line': line,
      'text': text,
      'dateKey': dateKey,
    };
  }

  factory PlannerNote.fromMap(Map<String, dynamic> map, [String defaultDateKey = '']) {
    return PlannerNote(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      page: map['page'] is int ? map['page'] : int.tryParse(map['page']?.toString() ?? '1') ?? 1,
      line: map['line'] is int ? map['line'] : int.tryParse(map['line']?.toString() ?? ''),
      text: map['text']?.toString() ?? '',
      dateKey: map['dateKey']?.toString() ?? defaultDateKey,
    );
  }
}

class DayLog {
  int parasRead;
  int pagesRead;
  int totalDayPages;
  String? dourPara;
  String? status; // 'completed' | 'partial' | 'pending'
  String? sabak;
  String? sabki;
  String? studentDour;
  String? generalTilawat;
  int pagesCount;
  List<PlannerNote> notes;
  List<QuranRange> readingRanges;
  List<ReadingSessionAssignment> readingSessions;
  List<HifzAssignment> hifzAssignments;
  List<HafezAssignment> hafezAssignments;

  DayLog({
    this.parasRead = 0,
    this.pagesRead = 0,
    int? totalDayPages,
    this.dourPara,
    this.status,
    this.sabak,
    this.sabki,
    this.studentDour,
    this.generalTilawat,
    this.pagesCount = 0,
    List<PlannerNote>? notes,
    List<QuranRange>? readingRanges,
    List<ReadingSessionAssignment>? readingSessions,
    List<HifzAssignment>? hifzAssignments,
    List<HafezAssignment>? hafezAssignments,
  })  : totalDayPages = totalDayPages ?? ((parasRead * 20) + pagesRead),
        notes = notes ?? [],
        readingRanges = readingRanges ?? [],
        readingSessions = readingSessions ?? [],
        hifzAssignments = hifzAssignments ?? [],
        hafezAssignments = hafezAssignments ?? [];

  Map<String, dynamic> toMap() {
    return {
      'parasRead': parasRead,
      'pagesRead': pagesRead,
      'totalDayPages': totalDayPages,
      'dourPara': dourPara,
      'status': status,
      'sabak': sabak,
      'sabki': sabki,
      'studentDour': studentDour,
      'generalTilawat': generalTilawat,
      'pagesCount': pagesCount,
      'notes': notes.map((n) => n.toMap()).toList(),
      'readingRanges': readingRanges.map((range) => range.toMap()).toList(),
      'readingSessions': readingSessions.map((session) => session.toMap()).toList(),
      'hifzAssignments': hifzAssignments.map((assignment) => assignment.toMap()).toList(),
      'hafezAssignments': hafezAssignments.map((assignment) => assignment.toMap()).toList(),
    };
  }

  factory DayLog.fromMap(Map<String, dynamic> map, [String dateKey = '']) {
    final rawNotes = map['notes'];
    final parsedNotes = <PlannerNote>[];
    if (rawNotes is List) {
      for (final n in rawNotes) {
        if (n is Map<String, dynamic>) {
          parsedNotes.add(PlannerNote.fromMap(n, dateKey));
        } else if (n is Map) {
          parsedNotes.add(PlannerNote.fromMap(Map<String, dynamic>.from(n), dateKey));
        }
      }
    }

    final rawRanges = map['readingRanges'];
    final parsedRanges = <QuranRange>[];
    if (rawRanges is List) {
      for (final range in rawRanges) {
        if (range is Map<String, dynamic>) {
          parsedRanges.add(QuranRange.fromMap(range));
        } else if (range is Map) {
          parsedRanges.add(QuranRange.fromMap(Map<String, dynamic>.from(range)));
        }
      }
    }

    final rawSessions = map['readingSessions'];
    final parsedSessions = <ReadingSessionAssignment>[];
    if (rawSessions is List) {
      for (final session in rawSessions) {
        if (session is Map<String, dynamic>) {
          parsedSessions.add(ReadingSessionAssignment.fromMap(session));
        } else if (session is Map) {
          parsedSessions.add(ReadingSessionAssignment.fromMap(Map<String, dynamic>.from(session)));
        }
      }
    }

    final rawHifzAssignments = map['hifzAssignments'];
    final parsedHifzAssignments = <HifzAssignment>[];
    if (rawHifzAssignments is List) {
      for (final assignment in rawHifzAssignments) {
        if (assignment is Map<String, dynamic>) {
          parsedHifzAssignments.add(HifzAssignment.fromMap(assignment));
        } else if (assignment is Map) {
          parsedHifzAssignments.add(
            HifzAssignment.fromMap(Map<String, dynamic>.from(assignment)),
          );
        }
      }
    }

    final rawHafezAssignments = map['hafezAssignments'];
    final parsedHafezAssignments = <HafezAssignment>[];
    if (rawHafezAssignments is List) {
      for (final assignment in rawHafezAssignments) {
        if (assignment is Map<String, dynamic>) {
          parsedHafezAssignments.add(HafezAssignment.fromMap(assignment));
        } else if (assignment is Map) {
          parsedHafezAssignments.add(
            HafezAssignment.fromMap(Map<String, dynamic>.from(assignment)),
          );
        }
      }
    }

    final pRead = map['parasRead'] is int
        ? map['parasRead'] as int
        : int.tryParse(map['parasRead']?.toString() ?? '0') ?? 0;

    final pgRead = map['pagesRead'] is int
        ? map['pagesRead'] as int
        : int.tryParse(map['pagesRead']?.toString() ?? '0') ?? 0;

    final calculatedTotal = (pRead * 20) + pgRead;

    final tPages = map['totalDayPages'] is int
        ? map['totalDayPages'] as int
        : int.tryParse(map['totalDayPages']?.toString() ?? '') ?? calculatedTotal;

    return DayLog(
      parasRead: pRead,
      pagesRead: pgRead,
      totalDayPages: tPages > 0 ? tPages : calculatedTotal,
      dourPara: map['dourPara']?.toString(),
      status: map['status']?.toString(),
      sabak: map['sabak']?.toString(),
      sabki: map['sabki']?.toString(),
      studentDour: map['studentDour']?.toString(),
      generalTilawat: map['generalTilawat']?.toString(),
      pagesCount: map['pagesCount'] is int
          ? map['pagesCount'] as int
          : int.tryParse(map['pagesCount']?.toString() ?? '0') ?? 0,
      notes: parsedNotes,
      readingRanges: parsedRanges,
      readingSessions: parsedSessions,
      hifzAssignments: parsedHifzAssignments,
      hafezAssignments: parsedHafezAssignments,
    );
  }
}

class PlannerModel {
  String profileMode; // 'general' | 'student' | 'hafiz'
  int hijriOffset;
  int targetDays;
  int pagesPerDay;
  String roadmapGoalMode;
  int planStartPage;
  String? planStartDate;
  List<ReadingSession> readerSessions;
  HifzSettings studentHifzSettings;
  List<MemorizedPortion> memorizedPortions;
  HafezSettings hafezSettings;
  List<HafezWeakPortion> hafezWeakPortions;
  bool reminderEnabled;
  String reminderTime;
  bool carryForwardMissedTasks;
  Map<String, DayLog> logs;

  PlannerModel({
    this.profileMode = 'general',
    this.hijriOffset = 0,
    this.targetDays = 30,
    this.pagesPerDay = 20,
    this.roadmapGoalMode = 'days',
    this.planStartPage = 1,
    this.planStartDate,
    List<ReadingSession>? readerSessions,
    this.studentHifzSettings = const HifzSettings(),
    List<MemorizedPortion>? memorizedPortions,
    this.hafezSettings = const HafezSettings(),
    List<HafezWeakPortion>? hafezWeakPortions,
    this.reminderEnabled = false,
    this.reminderTime = '06:00',
    this.carryForwardMissedTasks = false,
    Map<String, DayLog>? logs,
  })  : readerSessions = readerSessions ?? ReadingSession.defaults,
        memorizedPortions = memorizedPortions ?? [],
        hafezWeakPortions = hafezWeakPortions ?? [],
        logs = logs ?? {};

  Map<String, dynamic> toMap() {
    final logsMap = <String, dynamic>{};
    logs.forEach((key, val) {
      logsMap[key] = val.toMap();
    });
    return {
      'profileMode': profileMode,
      'hijriOffset': hijriOffset,
      'targetDays': targetDays,
      'pagesPerDay': pagesPerDay,
      'roadmapGoalMode': roadmapGoalMode,
      'planStartPage': planStartPage,
      'planStartDate': planStartDate,
      'readerSessions': readerSessions.map((session) => session.toMap()).toList(),
      'studentHifzSettings': studentHifzSettings.toMap(),
      'memorizedPortions': memorizedPortions.map((portion) => portion.toMap()).toList(),
      'hafezSettings': hafezSettings.toMap(),
      'hafezWeakPortions': hafezWeakPortions.map((portion) => portion.toMap()).toList(),
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'carryForwardMissedTasks': carryForwardMissedTasks,
      'logs': logsMap,
    };
  }

  factory PlannerModel.fromMap(Map<String, dynamic> map) {
    final parsedLogs = <String, DayLog>{};
    final rawLogs = map['logs'];
    if (rawLogs is Map) {
      rawLogs.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          parsedLogs[k.toString()] = DayLog.fromMap(v, k.toString());
        } else if (v is Map) {
          parsedLogs[k.toString()] = DayLog.fromMap(Map<String, dynamic>.from(v), k.toString());
        }
      });
    }
    final rawReaderSessions = map['readerSessions'];
    final readerSessions = <ReadingSession>[];
    if (rawReaderSessions is List) {
      for (final session in rawReaderSessions) {
        if (session is Map<String, dynamic>) {
          readerSessions.add(ReadingSession.fromMap(session));
        } else if (session is Map) {
          readerSessions.add(ReadingSession.fromMap(Map<String, dynamic>.from(session)));
        }
      }
    }
    final rawMemorizedPortions = map['memorizedPortions'];
    final memorizedPortions = <MemorizedPortion>[];
    if (rawMemorizedPortions is List) {
      for (final portion in rawMemorizedPortions) {
        if (portion is Map<String, dynamic>) {
          memorizedPortions.add(MemorizedPortion.fromMap(portion));
        } else if (portion is Map) {
          memorizedPortions.add(
            MemorizedPortion.fromMap(Map<String, dynamic>.from(portion)),
          );
        }
      }
    }
    final rawHifzSettings = map['studentHifzSettings'];
    final rawHafezWeakPortions = map['hafezWeakPortions'];
    final hafezWeakPortions = <HafezWeakPortion>[];
    if (rawHafezWeakPortions is List) {
      for (final portion in rawHafezWeakPortions) {
        if (portion is Map<String, dynamic>) {
          hafezWeakPortions.add(HafezWeakPortion.fromMap(portion));
        } else if (portion is Map) {
          hafezWeakPortions.add(
            HafezWeakPortion.fromMap(Map<String, dynamic>.from(portion)),
          );
        }
      }
    }
    final rawHafezSettings = map['hafezSettings'];
    return PlannerModel(
      profileMode: map['profileMode']?.toString() ?? 'general',
      hijriOffset: map['hijriOffset'] is int
          ? map['hijriOffset']
          : int.tryParse(map['hijriOffset']?.toString() ?? '0') ?? 0,
      targetDays: map['targetDays'] is int
          ? map['targetDays']
          : int.tryParse(map['targetDays']?.toString() ?? '30') ?? 30,
      pagesPerDay: map['pagesPerDay'] is int
          ? map['pagesPerDay']
          : int.tryParse(map['pagesPerDay']?.toString() ?? '20') ?? 20,
      roadmapGoalMode: map['roadmapGoalMode'] == 'pages' ? 'pages' : 'days',
      planStartPage: map['planStartPage'] is int
          ? map['planStartPage']
          : int.tryParse(map['planStartPage']?.toString() ?? '1') ?? 1,
      planStartDate: map['planStartDate']?.toString(),
      readerSessions: rawReaderSessions is List ? readerSessions : null,
      studentHifzSettings: rawHifzSettings is Map
          ? HifzSettings.fromMap(Map<String, dynamic>.from(rawHifzSettings))
          : const HifzSettings(),
      memorizedPortions: memorizedPortions,
      hafezSettings: rawHafezSettings is Map
          ? HafezSettings.fromMap(Map<String, dynamic>.from(rawHafezSettings))
          : const HafezSettings(),
      hafezWeakPortions: hafezWeakPortions,
      reminderEnabled: map['reminderEnabled'] == true,
      reminderTime: map['reminderTime']?.toString() ?? '06:00',
      carryForwardMissedTasks: map['carryForwardMissedTasks'] == true,
      logs: parsedLogs,
    );
  }
}
