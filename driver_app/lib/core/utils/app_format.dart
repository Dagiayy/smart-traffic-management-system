import 'package:intl/intl.dart';

class AppFormat {
  AppFormat._();

  static final _currency = NumberFormat.currency(
    symbol: 'ETB ',
    decimalDigits: 0,
    locale: 'en_ET',
  );

  static String currency(num value) => _currency.format(value);

  static double parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? parseNullableDouble(dynamic value) {
    if (value == null) return null;
    return parseDouble(value);
  }

  static String compact(num value) =>
      NumberFormat.compact(locale: 'en').format(value);

  static String date(DateTime d) => DateFormat('MMM d, y').format(d);

  static String dateTime(DateTime d) => DateFormat('MMM d, y • h:mm a').format(d);

  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  static String relative(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return date(d);
  }
}
