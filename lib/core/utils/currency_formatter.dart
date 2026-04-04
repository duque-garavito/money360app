import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    // Aquí puedes cambiar 'es_PE' al locale específico si deseas, y el símbolo a 'S/' o 'USD' u otro.
    final formatter = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2);
    return formatter.format(amount);
  }
}
