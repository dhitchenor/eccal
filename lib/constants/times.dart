import '../utils/app_localizations.dart';

// Month name constants for formatting dates
class MonthNames {
  // Full month names
  static List<String> get fullMonth => [
    'months.january'.tr(),
    'months.february'.tr(),
    'months.march'.tr(),
    'months.april'.tr(),
    'months.may'.tr(),
    'months.june'.tr(),
    'months.july'.tr(),
    'months.august'.tr(),
    'months.september'.tr(),
    'months.october'.tr(),
    'months.november'.tr(),
    'months.december'.tr(),
  ];

  // Abbreviated month names (3 letters)
  static List<String> get abbreviatedMonth => [
    'months.jan'.tr(),
    'months.feb'.tr(),
    'months.mar'.tr(),
    'months.apr'.tr(),
    'months.may'.tr(),
    'months.jun'.tr(),
    'months.jul'.tr(),
    'months.aug'.tr(),
    'months.sep'.tr(),
    'months.oct'.tr(),
    'months.nov'.tr(),
    'months.dec'.tr(),
  ];

  // Map for easy lookup by month number (1-12)
  static Map<int, String> get fullMonthMap => {
    1: 'months.january'.tr(),
    2: 'months.february'.tr(),
    3: 'months.march'.tr(),
    4: 'months.april'.tr(),
    5: 'months.may'.tr(),
    6: 'months.june'.tr(),
    7: 'months.july'.tr(),
    8: 'months.august'.tr(),
    9: 'months.september'.tr(),
    10: 'months.october'.tr(),
    11: 'months.november'.tr(),
    12: 'months.december'.tr(),
  };

  static Map<int, String> get abbreviatedMonthMap => {
    1: 'months.jan'.tr(),
    2: 'months.feb'.tr(),
    3: 'months.mar'.tr(),
    4: 'months.apr'.tr(),
    5: 'months.may'.tr(),
    6: 'months.jun'.tr(),
    7: 'months.jul'.tr(),
    8: 'months.aug'.tr(),
    9: 'months.sep'.tr(),
    10: 'months.oct'.tr(),
    11: 'months.nov'.tr(),
    12: 'months.dec'.tr(),
  };
}

// Weekday name constants for formatting dates
class WeekdayNames {
  // Full weekday names
  static List<String> get fullWeekday => [
    'weekdays.monday'.tr(),
    'weekdays.tuesday'.tr(),
    'weekdays.wednesday'.tr(),
    'weekdays.thursday'.tr(),
    'weekdays.friday'.tr(),
    'weekdays.saturday'.tr(),
    'weekdays.sunday'.tr(),
  ];

  // Abbreviated weekday names (3 letters)
  static List<String> get abbreviatedWeekday => [
    'weekdays.mon'.tr(),
    'weekdays.tue'.tr(),
    'weekdays.wed'.tr(),
    'weekdays.thu'.tr(),
    'weekdays.fri'.tr(),
    'weekdays.sat'.tr(),
    'weekdays.sun'.tr(),
  ];

  // Map for easy lookup by weekday number (1-7, Monday-Sunday)
  static Map<int, String> get fullWeekdayMap => {
    1: 'weekdays.monday'.tr(),
    2: 'weekdays.tuesday'.tr(),
    3: 'weekdays.wednesday'.tr(),
    4: 'weekdays.thursday'.tr(),
    5: 'weekdays.friday'.tr(),
    6: 'weekdays.saturday'.tr(),
    7: 'weekdays.sunday'.tr(),
  };

  static Map<int, String> get abbreviatedWeekdayMap => {
    1: 'weekdays.mon'.tr(),
    2: 'weekdays.tue'.tr(),
    3: 'weekdays.wed'.tr(),
    4: 'weekdays.thu'.tr(),
    5: 'weekdays.fri'.tr(),
    6: 'weekdays.sat'.tr(),
    7: 'weekdays.sun'.tr(),
  };
}

// Time name constants for formatting times
class timeNames {
  // Full time names (single)
  static List<String> get fullTime => [
    'times.second'.tr(),
    'times.minute'.tr(),
    'times.hour'.tr(),
    'times.day'.tr(),
    'times.month'.tr(),
    'times.year'.tr(),
  ];

  // Full time names (plural)
  static List<String> get fullTimes => [
    'times.seconds'.tr(),
    'times.minutes'.tr(),
    'times.hours'.tr(),
    'times.days'.tr(),
    'times.months'.tr(),
    'times.years'.tr(),
  ];

  // Abbreviated time names (single)
  static List<String> get abbreviatedTime => [
    'times.sec'.tr(),
    'times.min'.tr(),
    'times.hr'.tr(),
    'times.dy'.tr(),
    'times.mo'.tr(),
    'times.yr'.tr(),
  ];

  // Abbreviated time names (plural)
  static List<String> get abbreviatedTimes => [
    'times.secs'.tr(),
    'times.mins'.tr(),
    'times.hrs'.tr(),
    'times.dys'.tr(),
    'times.mos'.tr(),
    'times.yrs'.tr(),
  ];

  // Map for easy lookup of full time unit (single)
  static Map<String, String> get fullTimeMap => {
    'second': 'times.second'.tr(),
    'minute': 'times.minute'.tr(),
    'hour': 'times.hour'.tr(),
    'day': 'times.day'.tr(),
    'month': 'times.month'.tr(),
    'year': 'times.year'.tr(),
  };

  // Map for easy lookup of full time unit (plural)
  static Map<String, String> get fullTimesMap => {
    'seconds': 'times.seconds'.tr(),
    'minutes': 'times.minutes'.tr(),
    'hours': 'times.hours'.tr(),
    'days': 'times.days'.tr(),
    'months': 'times.months'.tr(),
    'years': 'times.years'.tr(),
  };

  // Map for easy lookup of abreviated time unit (single)
  static Map<String, String> get abbreviatedTimeMap => {
    'second': 'times.sec'.tr(),
    'minute': 'times.min'.tr(),
    'hour': 'times.hr'.tr(),
    'day': 'times.dy'.tr(),
    'month': 'times.mo'.tr(),
    'year': 'times.yr'.tr(),
  };

  // Map for easy lookup of abreviated time unit (plural)
  static Map<String, String> get abbreviatedTimesMap => {
    'seconds': 'times.secs'.tr(),
    'minutes': 'times.mins'.tr(),
    'hours': 'times.hrs'.tr(),
    'days': 'times.dys'.tr(),
    'months': 'times.mos'.tr(),
    'years': 'times.yrs'.tr(),
  };
}