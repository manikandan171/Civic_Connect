import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('bn'), // Bengali
    Locale('or'), // Odia
    Locale('ta'), // Tamil
  ];
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  // Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('selected_language') ?? 'en';
      
      // Validate if the saved language is supported
      final savedLocale = Locale(savedLanguageCode);
      if (supportedLocales.contains(savedLocale)) {
        _currentLocale = savedLocale;
      } else {
        _currentLocale = const Locale('en'); // Default to English
      }
      
      notifyListeners();
      debugPrint('🌐 Loaded saved language: ${_currentLocale.languageCode}');
    } catch (e) {
      debugPrint('❌ Error loading saved language: $e');
      _currentLocale = const Locale('en'); // Default to English on error
    }
  }
  
  // Change language and save to SharedPreferences
  Future<void> changeLanguage(String languageCode) async {
    try {
      final newLocale = Locale(languageCode);
      
      // Validate if the language is supported
      if (!supportedLocales.contains(newLocale)) {
        debugPrint('❌ Unsupported language: $languageCode');
        return;
      }
      
      _currentLocale = newLocale;
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);
      
      notifyListeners();
      debugPrint('🌐 Language changed to: $languageCode');
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
    }
  }
  
  // Get language name in native script
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      case 'bn':
        return 'বাংলা';
      case 'or':
        return 'ଓଡ଼ିଆ';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }
  
  // Get language name in English
  String getLanguageNameInEnglish(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'Hindi';
      case 'bn':
        return 'Bengali';
      case 'or':
        return 'Odia';
      case 'ta':
        return 'Tamil';
      default:
        return 'English';
    }
  }
  
  // Check if current language is RTL (Right-to-Left)
  bool get isRTL {
    // Add RTL languages here if needed in future
    // Currently, none of our supported languages are RTL
    return false;
  }
  
  // Get text direction based on current language
  TextDirection get textDirection {
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  }
}
