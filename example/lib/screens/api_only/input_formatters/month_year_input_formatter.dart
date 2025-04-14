import 'package:flutter/services.dart';

class MonthYearInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    final int newTextLength = newText.length;
    final int oldTextLength = oldValue.text.length;

    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (newTextLength == 1 &&
        int.tryParse(newText) != null &&
        int.parse(newText) >= 2 &&
        oldTextLength == 0) {
      return newValue.copyWith(
        text: '0$newText',
        selection: const TextSelection.collapsed(offset: 2),
      );
    }

    if (newTextLength > 4) {
      return oldValue;
    }

    final formattedText = newTextLength > 2
        ? '${newText.substring(0, 2)}/${newText.substring(2)}'
        : newText;
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
