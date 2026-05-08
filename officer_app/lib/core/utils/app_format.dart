import 'package:intl/intl.dart';

class AppFormat {
  AppFormat._();
  static final _currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0, locale: 'en_ET');

  static String currency(num v) => _currency.format(v);
  static String date(DateTime d) => DateFormat('MMM d, y').format(d);
  static String dateTime(DateTime d) => DateFormat('MMM d, y  HH:mm').format(d);
  static String time(DateTime d) => DateFormat('HH:mm').format(d);
  static String shortDate(DateTime d) => DateFormat('d MMM').format(d);

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(d);
  }
}
