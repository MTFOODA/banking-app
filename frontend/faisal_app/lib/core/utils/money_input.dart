import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String normalizeMoney(String text) {
  var value = text;
  for (var i = 0; i < 10; i++) {
    value = value
        .replaceAll(String.fromCharCode(0x660 + i), '$i')
        .replaceAll(String.fromCharCode(0x6f0 + i), '$i');
  }
  return value.replaceAll(',', '').replaceAll('٬', '').replaceAll('٫', '.');
}

class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = normalizeMoney(newValue.text);
    if (raw.isEmpty) return newValue;
    if (!RegExp(r'^\d{0,9}(\.\d{0,2})?$').hasMatch(raw)) return oldValue;
    final parts = raw.split('.');
    final whole = parts[0].isEmpty
        ? '0'
        : NumberFormat('#,##0', 'en').format(int.parse(parts[0]));
    final formatted = parts.length == 2 ? '$whole.${parts[1]}' : whole;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
