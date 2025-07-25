import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  String _currentLanguage = 'en'; // Default to English

  String get currentLanguage => _currentLanguage;

  // Initialize language from storage
  Future<void> initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'en';
    notifyListeners();
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }

  // Toggle between English and Arabic
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == 'en' ? 'ar' : 'en';
    await changeLanguage(newLanguage);
  }

  // Check if current language is Arabic
  bool get isArabic => _currentLanguage == 'ar';

  // Check if current language is English
  bool get isEnglish => _currentLanguage == 'en';

  // Get text direction for current language
  TextDirection get textDirection => _currentLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  // Check if current language is RTL
  bool get isRTL => _currentLanguage == 'ar';
} 