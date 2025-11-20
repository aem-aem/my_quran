import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  Future<void> setLanguage(String language) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setString('language', language);
  }

  Future<String> loadLanguage() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final language = sharedPrefs.getString('language') ?? 'ar';
    return language;
  }

  Future<void> setFontFamily(String fontFamily) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setString('fontFamily', fontFamily);
  }

  Future<String> loadFontFamily() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final fontFamily = sharedPrefs.getString('fontFamily') ?? 'Hafs';
    return fontFamily;
  }

  Future<void> setFontSize(int fontSize) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setInt('fontSize', fontSize);
  }

  Future<int> loadFontSize() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final fontSize = sharedPrefs.getInt('fontSize') ?? 18;
    return fontSize;
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setInt('theme', themeMode.index);
  }

  Future<ThemeMode> loadTheme() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final themeIndex = sharedPrefs.getInt('theme') ?? 0;
    return ThemeMode.values[themeIndex];
  }
}
