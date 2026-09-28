import 'package:intl/intl.dart';

/// Utilitaires de dates pour le journal alimentaire et les graphiques.
class DateUtils {
  DateUtils._();

  static final DateFormat _dayFull = DateFormat('EEEE d MMMM', 'fr_FR');
  static final DateFormat _dayShort = DateFormat('EEE', 'fr_FR');
  static final DateFormat _dateMedium = DateFormat('d MMM yyyy', 'fr_FR');
  static final DateFormat _time = DateFormat('HH:mm');

  static String dayLabel(DateTime date) => _dayFull.format(date);

  static String shortDayLabel(DateTime date) => _dayShort.format(date);

  static String dateLabel(DateTime date) => _dateMedium.format(date);

  static String timeLabel(DateTime date) => _time.format(date);

  /// Ne conserve que la date (minuit local).
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// Les 7 derniers jours (hier inclus), du plus ancien au plus récent.
  static List<DateTime> last7Days([DateTime? end]) {
    final last = dateOnly(end ?? DateTime.now());
    return List.generate(7, (i) => last.subtract(Duration(days: 6 - i)));
  }

  /// Intervalle [début, fin] en jours inclusifs.
  static int daysBetween(DateTime from, DateTime to) =>
      dateOnly(to).difference(dateOnly(from)).inDays;

  static String relativeLabel(DateTime date) {
    final diff = daysBetween(date, DateTime.now());
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    if (diff == -1) return 'Demain';
    return dateLabel(date);
  }
}
