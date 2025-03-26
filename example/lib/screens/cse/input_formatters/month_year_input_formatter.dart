import 'package:flutter/services.dart';

class MonthYearInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final textLength = text.length;
    final oldLength = oldValue.text.length;

    if (textLength == 0) return newValue.copyWith(text: '');
    if (textLength == 1 &&
        int.tryParse(text) != null &&
        int.parse(text) >= 2 &&
        oldLength == 0) {
      return newValue.copyWith(
        text: '0$text',
        selection: const TextSelection.collapsed(offset: 2),
      );
    }
    if (textLength > 4) return oldValue;

    final formattedText =
        textLength > 2 ? '${text.substring(0, 2)}/${text.substring(2)}' : text;
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  static String parseMonthYear(String formattedDate) =>
      formattedDate.replaceAll(RegExp(r'\D'), '').length == 4
          ? formattedDate.replaceAll(RegExp(r'\D'), '')
          : '';
}
