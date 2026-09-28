import 'package:intl/intl.dart';

/// Formatage des nombres, montants, calories, etc.
class Formatters {
  Formatters._();

  static final NumberFormat _kcal = NumberFormat('#,###');
  static final NumberFormat _gram = NumberFormat('#,##0.#');
  static final NumberFormat _weight = NumberFormat('#,##0.0');

  static String kcal(num value) => '${_kcal.format(value.round())} kcal';

  static String grams(num value) => '${_gram.format(value)} g';

  static String kg(num value) => '${_weight.format(value)} kg';

  static String percent(num value) => '${value.round()} %';

  static String number(num value) => _kcal.format(value);
}
