import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  static const _key = 'theme_mode';

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? true; // Default to Dark
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() async {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_key, value == ThemeMode.dark);
  }
}

// Global theme notifier instance
final ThemeNotifier themeNotifier = ThemeNotifier();
