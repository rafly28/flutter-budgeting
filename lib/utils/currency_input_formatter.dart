import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern("id_ID");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // kalau kosong
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // buang semua tanda non-digit
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final number = int.parse(digitsOnly);

    final newString = _formatter.format(number);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }

  static String format(double value) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(value);
  }
}
