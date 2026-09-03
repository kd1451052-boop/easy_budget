import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    // Handle multiple decimals
    if (cleanText.contains('.')) {
      int firstDot = cleanText.indexOf('.');
      cleanText = cleanText.substring(0, firstDot + 1) + cleanText.substring(firstDot + 1).replaceAll('.', '');
    }

    if (cleanText.isEmpty || cleanText == '.') {
      return newValue.copyWith(text: cleanText);
    }

    List<String> parts = cleanText.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    if (integerPart.isNotEmpty) {
      final value = int.parse(integerPart);
      final formatter = NumberFormat("#,##0", "en_US");
      integerPart = formatter.format(value);
    }

    String newText = integerPart;
    if (cleanText.contains('.')) {
      newText += '.$decimalPart';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
