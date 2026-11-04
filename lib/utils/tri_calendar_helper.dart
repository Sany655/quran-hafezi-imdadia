class BengaliDate {
  final int day;
  final int monthIndex;
  final String monthName;
  final int year;

  BengaliDate({
    required this.day,
    required this.monthIndex,
    required this.monthName,
    required this.year,
  });
}

class HijriDate {
  final int day;
  final int monthIndex;
  final String monthName;
  final int year;
  final bool isAyyamAlBeed;
  final bool isRamadan;

  HijriDate({
    required this.day,
    required this.monthIndex,
    required this.monthName,
    required this.year,
    required this.isAyyamAlBeed,
    required this.isRamadan,
  });
}

class TriCalendarHelper {
  static const List<String> bengaliDigits = [
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'
  ];

  static const List<String> bengaliMonths = [
    'বৈশাখ', 'জ্যৈষ্ঠ', 'আষাঢ়', 'শ্রাবণ', 'ভাদ্র', 'আশ্বিন',
    'কার্তিক', 'অগ্রহায়ণ', 'পৌষ', 'মাঘ', 'ফাল্গুন', 'চৈত্র'
  ];

  static const List<String> hijriMonths = [
    'মুহররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি',
    'জমাদিউল আউয়াল', 'জমাদিউস সানি', 'রজব', 'শাবান',
    'রমাদান', 'শাওয়াল', 'জিলক্বদ', 'জিলহজ্জ'
  ];

  static const List<String> gregorianMonthsBn = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];

  static String toBnNum(dynamic num) {
    return num.toString().split('').map((char) {
      final code = char.codeUnitAt(0);
      if (code >= 48 && code <= 57) {
        return bengaliDigits[code - 48];
      }
      return char;
    }).join('');
  }

  static BengaliDate getBengaliDate(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final bYear = (m > 4 || (m == 4 && d >= 14)) ? y - 593 : y - 594;
    final start = DateTime(y, 4, 14);
    int diffDays = date.difference(start).inDays;
    if (diffDays < 0) {
      final prevStart = DateTime(y - 1, 4, 14);
      diffDays = date.difference(prevStart).inDays;
    }
    final isLeap = (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
    final monthDays = [31, 31, 31, 31, 31, 30, 30, 30, 30, 30, isLeap ? 31 : 30, 30];
    int curr = diffDays;
    for (int i = 0; i < monthDays.length; i++) {
      if (curr < monthDays[i]) {
        return BengaliDate(
          day: curr + 1,
          monthIndex: i,
          monthName: bengaliMonths[i],
          year: bYear,
        );
      }
      curr -= monthDays[i];
    }
    return BengaliDate(
      day: 1,
      monthIndex: 0,
      monthName: bengaliMonths[0],
      year: bYear,
    );
  }

  static HijriDate getHijriDate(DateTime date, [int offset = 0]) {
    int year = date.year;
    int month = date.month;
    int day = date.day;
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final double a = (year / 100).floorToDouble();
    final double b = 2 - a + (a / 4).floorToDouble();
    double jd = (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        day +
        b -
        1524.5;
    jd += offset;
    final double z = (jd + 0.5).floorToDouble();
    final double cyc = ((z - 1948439.5) / 10631).floorToDouble();
    final double rem = (z - 1948439.5) - 10631 * cyc;
    final double j = ((rem + 0.5) / 354.366).floorToDouble();
    final double rem2 = rem - (j * 354.366 + 0.5).floorToDouble();
    final int hYear = (30 * cyc + j + 1).toInt();
    int hMonth = ((rem2 + 28.5001) / 29.5).floor();
    if (hMonth > 12) hMonth = 12;
    if (hMonth < 1) hMonth = 1;
    int hDay = (rem2 - (29.5001 * hMonth - 29).floor() + 1).toInt();
    if (hDay > 30) hDay = 30;
    if (hDay < 1) hDay = 1;

    return HijriDate(
      day: hDay,
      monthIndex: hMonth - 1,
      monthName: hijriMonths[hMonth - 1],
      year: hYear,
      isAyyamAlBeed: (hDay == 13 || hDay == 14 || hDay == 15),
      isRamadan: (hMonth == 9),
    );
  }

  static String formatTriDateFull(DateTime date, [int offset = 0]) {
    final gDay = date.day;
    final gMonth = gregorianMonthsBn[date.month - 1];
    final gYear = date.year;
    final bn = getBengaliDate(date);
    final hj = getHijriDate(date, offset);
    return '${toBnNum(gDay)} $gMonth ${toBnNum(gYear)} • ${toBnNum(bn.day)} ${bn.monthName} ${toBnNum(bn.year)} • ${toBnNum(hj.day)} ${hj.monthName} ${toBnNum(hj.year)}';
  }

  static String formatDateKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
