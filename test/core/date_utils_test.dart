import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vitatrack/core/utils/date_utils.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  group('DateUtils.dateOnly', () {
    test('neutralise l\'heure (minuit local)', () {
      final d = DateUtils.dateOnly(DateTime(2026, 5, 10, 14, 30, 45));
      expect(d, DateTime(2026, 5, 10));
    });
  });

  group('DateUtils.isSameDay', () {
    test('ignore l\'heure et compare jour/mois/année', () {
      expect(
        DateUtils.isSameDay(
            DateTime(2026, 3, 1, 8), DateTime(2026, 3, 1, 22, 59)),
        isTrue,
      );
      expect(
        DateUtils.isSameDay(
            DateTime(2026, 3, 1), DateTime(2026, 3, 2)),
        isFalse,
      );
    });
  });

  group('DateUtils.isToday', () {
    test('vrai uniquement pour la date courante', () {
      expect(DateUtils.isToday(DateTime.now()), isTrue);
      expect(DateUtils.isToday(DateTime.now().subtract(const Duration(days: 1))), isFalse);
    });
  });

  group('DateUtils.last7Days', () {
    test('retourne 7 jours triés du plus ancien au plus récent, finissant aujourd\'hui', () {
      final days = DateUtils.last7Days(DateTime(2026, 6, 10, 15));
      expect(days.length, 7);
      expect(days.first, DateTime(2026, 6, 4));
      expect(days.last, DateTime(2026, 6, 10));
      // croissant
      for (var i = 1; i < days.length; i++) {
        expect(days[i].isAfter(days[i - 1]), isTrue);
      }
    });
  });

  group('DateUtils.daysBetween', () {
    test('calcule un intervalle en jours inclusifs', () {
      expect(DateUtils.daysBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 11)), 10);
      expect(DateUtils.daysBetween(DateTime(2026, 1, 5), DateTime(2026, 1, 1)), -4);
    });
  });

  group('DateUtils.relativeLabel', () {
    test('Aujourd\'hui / Hier / Demain', () {
      final today = DateTime.now();
      expect(DateUtils.relativeLabel(today), 'Aujourd\'hui');
      expect(DateUtils.relativeLabel(today.subtract(const Duration(days: 1))), 'Hier');
      expect(DateUtils.relativeLabel(today.add(const Duration(days: 1))), 'Demain');
    });

    test('au-delà affiche la date formatée', () {
      final label = DateUtils.relativeLabel(DateTime(2020, 1, 1));
      expect(label, contains('2020'));
    });
  });

  group('DateUtils labels formatés', () {
    test('dateLabel et timeLabel produisent un format lisible', () {
      expect(DateUtils.dateLabel(DateTime(2026, 9, 28)), '28 sept. 2026');
      expect(DateUtils.timeLabel(DateTime(2026, 9, 28, 8, 5)), '08:05');
    });
  });
}
