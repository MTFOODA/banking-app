import 'package:intl/intl.dart';

/// Locale-aware currency and date formatting (English and Arabic).
class FaisalFormatters {
  const FaisalFormatters._();

  static String money(
    double amount, {
    String currency = 'EGP',
    String locale = 'en',
  }) {
    final symbol = currency == 'EGP'
        ? (locale.startsWith('ar') ? 'ج.م' : 'EGP')
        : currency;
    final format = NumberFormat.currency(
      locale: locale.startsWith('ar') ? 'ar_EG' : 'en_EG',
      symbol: symbol,
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String compactMoney(
    double amount, {
    String currency = 'EGP',
    String locale = 'en',
  }) {
    final symbol = currency == 'EGP'
        ? (locale.startsWith('ar') ? 'ج.م' : 'EGP')
        : currency;
    final format = NumberFormat.compactCurrency(
      locale: locale.startsWith('ar') ? 'ar_EG' : 'en_EG',
      symbol: symbol,
      decimalDigits: 1,
    );
    return format.format(amount);
  }

  static String date(DateTime value, {String locale = 'en'}) =>
      DateFormat.yMMMd(locale).format(value);

  static String dateTime(DateTime value, {String locale = 'en'}) =>
      DateFormat.yMMMd(locale).add_jm().format(value);

  static String monthYear(int month, int year, {String locale = 'en'}) {
    final date = DateTime(year, month.clamp(1, 12), 1);
    return DateFormat.yM(locale).format(date);
  }

  static String relativeDay(DateTime value, {String locale = 'en'}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final difference = target.difference(today).inDays;
    if (difference == 0) {
      return locale.startsWith('ar') ? 'اليوم' : 'Today';
    }
    if (difference == -1) {
      return locale.startsWith('ar') ? 'أمس' : 'Yesterday';
    }
    return date(value, locale: locale);
  }

  static String maskCard(String last4) => '•••• •••• •••• $last4';

  static String formatCardInput(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && index % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}
