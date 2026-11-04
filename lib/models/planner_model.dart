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
  })  : totalDayPages = totalDayPages ?? ((parasRead * 20) + pagesRead),
        notes = notes ?? [];

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
    );
  }
}

class PlannerModel {
  String profileMode; // 'general' | 'student' | 'hafiz'
  int hijriOffset;
  int targetDays;
  int pagesPerDay;
  bool reminderEnabled;
  String reminderTime;
  Map<String, DayLog> logs;

  PlannerModel({
    this.profileMode = 'general',
    this.hijriOffset = 0,
    this.targetDays = 30,
    this.pagesPerDay = 20,
    this.reminderEnabled = false,
    this.reminderTime = '06:00',
    Map<String, DayLog>? logs,
  }) : logs = logs ?? {};

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
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
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
      reminderEnabled: map['reminderEnabled'] == true,
      reminderTime: map['reminderTime']?.toString() ?? '06:00',
      logs: parsedLogs,
    );
  }
}
