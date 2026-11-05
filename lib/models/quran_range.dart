class QuranRange {
  final int startSurahId;
  final int startAyahNumber;
  final int endSurahId;
  final int endAyahNumber;
  final int startPage;
  final int endPage;

  const QuranRange({
    required this.startSurahId,
    required this.startAyahNumber,
    required this.endSurahId,
    required this.endAyahNumber,
    required this.startPage,
    required this.endPage,
  });

  bool isValid(Map<int, int> ayahCounts) {
    final startCount = ayahCounts[startSurahId];
    final endCount = ayahCounts[endSurahId];
    if (startCount == null || endCount == null) return false;
    if (startAyahNumber < 1 || startAyahNumber > startCount) return false;
    if (endAyahNumber < 1 || endAyahNumber > endCount) return false;
    if (startPage < 1 || endPage > 612 || startPage > endPage) return false;
    return startSurahId < endSurahId ||
        (startSurahId == endSurahId && startAyahNumber <= endAyahNumber);
  }

  Map<String, dynamic> toMap() => {
        'startSurahId': startSurahId,
        'startAyahNumber': startAyahNumber,
        'endSurahId': endSurahId,
        'endAyahNumber': endAyahNumber,
        'startPage': startPage,
        'endPage': endPage,
      };

  factory QuranRange.fromMap(Map<String, dynamic> map) {
    int readInt(String key) {
      final value = map[key];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return QuranRange(
      startSurahId: readInt('startSurahId'),
      startAyahNumber: readInt('startAyahNumber'),
      endSurahId: readInt('endSurahId'),
      endAyahNumber: readInt('endAyahNumber'),
      startPage: readInt('startPage'),
      endPage: readInt('endPage'),
    );
  }
}
