import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  static const _key = 'language_code';

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_key) ?? 'en';
    value = Locale(languageCode);
  }

  void setLocale(String languageCode) async {
    value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, languageCode);
  }
}

// Global locale notifier instance
final LocaleNotifier localeNotifier = LocaleNotifier();
