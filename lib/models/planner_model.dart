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
  String? dourPara;
  String? status; // 'completed' | 'partial' | 'pending'
  String? sabak;
  String? sabki;
  String? studentDour;
  String? generalTilawat;
  List<PlannerNote> notes;

  DayLog({
    this.dourPara,
    this.status,
    this.sabak,
    this.sabki,
    this.studentDour,
    this.generalTilawat,
    List<PlannerNote>? notes,
  }) : notes = notes ?? [];

  Map<String, dynamic> toMap() {
    return {
      'dourPara': dourPara,
      'status': status,
      'sabak': sabak,
      'sabki': sabki,
      'studentDour': studentDour,
      'generalTilawat': generalTilawat,
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
    return DayLog(
      dourPara: map['dourPara']?.toString(),
      status: map['status']?.toString(),
      sabak: map['sabak']?.toString(),
      sabki: map['sabki']?.toString(),
      studentDour: map['studentDour']?.toString(),
      generalTilawat: map['generalTilawat']?.toString(),
      notes: parsedNotes,
    );
  }
}

class PlannerModel {
  String profileMode; // 'general' | 'student' | 'hafiz'
  int hijriOffset;
  Map<String, DayLog> logs;

  PlannerModel({
    this.profileMode = 'general',
    this.hijriOffset = 0,
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
      hijriOffset: map['hijriOffset'] is int ? map['hijriOffset'] : int.tryParse(map['hijriOffset']?.toString() ?? '0') ?? 0,
      logs: parsedLogs,
    );
  }
}
