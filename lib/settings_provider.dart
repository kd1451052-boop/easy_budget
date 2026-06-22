import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  static const String boxName = 'settingsBox';
  late Box _box;

  SettingsProvider() {
    _box = Hive.box(boxName);
  }

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  // --- Theme Mode ---
  ThemeMode get themeMode {
    final isDark = _box.get('isDarkMode', defaultValue: false);
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => _box.get('isDarkMode', defaultValue: false);

  void toggleTheme(bool isDark) {
    _box.put('isDarkMode', isDark);
    notifyListeners();
  }

  // --- Profile Name ---
  String get userName => _box.get('userName', defaultValue: 'John Doe');

  void updateUserName(String newName) {
    _box.put('userName', newName);
    notifyListeners();
  }

  // --- Currency ---
  String get selectedCurrency => _box.get('selectedCurrency', defaultValue: 'USD');

  void updateCurrency(String newCurrency) {
    _box.put('selectedCurrency', newCurrency);
    notifyListeners();
  }

  String get currencySymbol {
    switch (selectedCurrency) {
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'AUD': return 'A\$';
      case 'CAD': return 'C\$';
      case 'USD':
      default: return '\$';
    }
  }

  // --- Language ---
  String get selectedLanguage => _box.get('selectedLanguage', defaultValue: 'English');

  void updateLanguage(String newLanguage) {
    _box.put('selectedLanguage', newLanguage);
    notifyListeners();
  }
}
