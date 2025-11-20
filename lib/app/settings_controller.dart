import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:my_quran/app/services/settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required this.settingsService});

  final SettingsService settingsService;

  String _language = 'ar';
  String _fontFamily = 'kitab';
  int _fontSize = 18;
  ThemeMode _theme = ThemeMode.system;

  String get language => _language;
  set language(String value) {
    _language = value;
    notifyListeners();
    settingsService.setLanguage(value);
  }

  String get fontFamily => _fontFamily;
  set fontFamily(String value) {
    _fontFamily = value;
    notifyListeners();
    settingsService.setFontFamily(value);
  }

  int get fontSize => _fontSize;
  set fontSize(int value) {
    _fontSize = value;
    notifyListeners();
    settingsService.setFontSize(value);
  }

  ThemeMode get themeMode => _theme;
  set themeMode(ThemeMode value) {
    _theme = value;
    notifyListeners();
    settingsService.setTheme(value);
  }

  void toggleTheme() {
    themeMode = switch (themeMode) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
  }
}
