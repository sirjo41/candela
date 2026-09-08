import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State management for app locale (Arabic 'ar' vs English 'en') with SharedPreferences persistence.
class LocaleProvider extends ChangeNotifier {
  static const String _localePrefKey = 'candela_app_locale_code';

  Locale _locale = const Locale('ar'); // Default to Arabic RTL

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  LocaleProvider() {
    _loadLocalePreference();
  }

  Future<void> _loadLocalePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString(_localePrefKey);
      if (langCode == 'en') {
        _locale = const Locale('en');
      } else {
        _locale = const Locale('ar');
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleLocale() async {
    if (_locale.languageCode == 'ar') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('ar');
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePrefKey, _locale.languageCode);
    } catch (_) {}
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePrefKey, _locale.languageCode);
    } catch (_) {}
  }
}
