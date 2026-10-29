import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsProvider extends ChangeNotifier {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  // --- Theme Mode ---
  ThemeMode get themeMode {
    final isDark = prefs.getBool('isDarkMode') ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => prefs.getBool('isDarkMode') ?? false;

  void toggleTheme(bool isDark) {
    prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  bool get isGuestUser => prefs.getBool('isGuestUser') ?? false;

  void setGuestUser(bool isGuest) {
    prefs.setBool('isGuestUser', isGuest);
    notifyListeners();
  }

  // --- Profile Details ---
  String get userName {
    if (isGuestUser) return 'Guest';
    
    final name = prefs.getString('userName');
    if (name != null && name.isNotEmpty) return name;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return user.email ?? user.phoneNumber ?? 'User';
      }
    } catch (e) {
      // Ignore auth errors during init
    }
    return 'John Doe';
  }

  void updateUserName(String newName) {
    prefs.setString('userName', newName);
    notifyListeners();
  }

  String get profilePicture => prefs.getString('profilePicture') ?? '';

  void updateProfilePicture(String url) {
    prefs.setString('profilePicture', url);
    notifyListeners();
  }

  String get profileFrame => prefs.getString('profileFrame') ?? 'none';

  void updateProfileFrame(String frame) {
    prefs.setString('profileFrame', frame);
    notifyListeners();
  }

  // --- Currency ---
  String get selectedCurrency => prefs.getString('selectedCurrency') ?? 'USD';

  void updateCurrency(String newCurrency) {
    prefs.setString('selectedCurrency', newCurrency);
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

  /// Returns false for currencies that do not use decimal subunits (e.g., JPY ¥).
  bool get currencyHasDecimals {
    switch (selectedCurrency) {
      case 'JPY':
      case 'KRW':
        return false;
      default:
        return true;
    }
  }

  /// Formats [amount] with `.00` only if the active currency uses decimals.
  String formatAmount(double amount) {
    final pattern = currencyHasDecimals ? '#,##0.00' : '#,##0';
    return NumberFormat(pattern, 'en_US').format(amount);
  }

  // --- Language ---
  String get selectedLanguage => prefs.getString('selectedLanguage') ?? 'English';

  Locale get locale {
    switch (selectedLanguage) {
      case 'Spanish': return const Locale('es');
      case 'French': return const Locale('fr');
      case 'German': return const Locale('de');
      case 'Japanese': return const Locale('ja');
      case 'Korean': return const Locale('ko');
      case 'English':
      default: return const Locale('en');
    }
  }

  void updateLanguage(String newLanguage) {
    prefs.setString('selectedLanguage', newLanguage);
    notifyListeners();
  }

  // --- Onboarding & Auth ---
  bool get hasCompletedOnboarding => prefs.getBool('hasCompletedOnboarding') ?? false;

  void updateHasCompletedOnboarding(bool completed) {
    prefs.setBool('hasCompletedOnboarding', completed);
    notifyListeners();
  }

  bool get rememberMe => prefs.getBool('rememberMe') ?? false;

  void updateRememberMe(bool remember) {
    prefs.setBool('rememberMe', remember);
    notifyListeners();
  }

  String get rememberedEmail => prefs.getString('rememberedEmail') ?? '';

  void updateRememberedEmail(String email) {
    prefs.setString('rememberedEmail', email);
    notifyListeners();
  }

  // --- Custom Categories ---
  Map<String, int> get customExpenseCategories {
    final String? jsonStr = prefs.getString('customExpenseCategories');
    if (jsonStr == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  void addCustomExpenseCategory(String name, int iconCodePoint) {
    final map = customExpenseCategories;
    map[name] = iconCodePoint;
    prefs.setString('customExpenseCategories', jsonEncode(map));
    notifyListeners();
  }

  void removeCustomExpenseCategory(String name) {
    final map = customExpenseCategories;
    map.remove(name);
    prefs.setString('customExpenseCategories', jsonEncode(map));
    notifyListeners();
  }

  Map<String, int> get customIncomeCategories {
    final String? jsonStr = prefs.getString('customIncomeCategories');
    if (jsonStr == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  void addCustomIncomeCategory(String name, int iconCodePoint) {
    final map = customIncomeCategories;
    map[name] = iconCodePoint;
    prefs.setString('customIncomeCategories', jsonEncode(map));
    notifyListeners();
  }

  void removeCustomIncomeCategory(String name) {
    final map = customIncomeCategories;
    map.remove(name);
    prefs.setString('customIncomeCategories', jsonEncode(map));
    notifyListeners();
  }

  // --- Guest Scan Limits ---
  bool get canGuestScan {
    if (!isGuestUser) return true;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastScanDate = prefs.getString('lastScanDate') ?? '';
    final count = prefs.getInt('guestScanCount') ?? 0;
    
    if (lastScanDate != today) {
      return true; // New day, can scan
    }
    return count < 10;
  }

  void incrementGuestScanCount() {
    if (!isGuestUser) return;
    
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastScanDate = prefs.getString('lastScanDate') ?? '';
    
    if (lastScanDate != today) {
      prefs.setString('lastScanDate', today);
      prefs.setInt('guestScanCount', 1);
    } else {
      final count = prefs.getInt('guestScanCount') ?? 0;
      prefs.setInt('guestScanCount', count + 1);
    }
    notifyListeners();
  }
}
