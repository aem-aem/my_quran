import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/pages/home_page.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/services/reading_position_service.dart';
import 'package:my_quran/app/services/search_service.dart';
import 'package:my_quran/app/services/settings_service.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:quran/quran.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize search index in background
  unawaited(SearchService.init());
  await Quran.initialize();
  await BookmarkService().initialize();
  await FontSizeController().initialize();

  final lastPosition = await ReadingPositionService.loadPosition();
  debugPrint('📱 Last Position: $lastPosition');
  final settingsController = SettingsController(
    settingsService: SettingsService(),
  );
  await settingsController.init();
  runApp(MyApp(lastPosition, settingsController));
}

class MyApp extends StatelessWidget {
  const MyApp(this.lastPosition, this.settingsController, {super.key});
  final ReadingPosition? lastPosition;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
        return MaterialApp(
          title: 'My Quran',
          debugShowCheckedModeBanner: false,
          locale: Locale(settingsController.language),
          supportedLocales: const [Locale('ar')],
          themeMode: settingsController.themeMode,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          darkTheme: ThemeData(
            fontFamily: settingsController.fontFamily.name,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: Colors.lightGreen.shade900,
            ),
          ),
          theme: ThemeData(
            fontFamily: settingsController.fontFamily.name,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightGreen.shade900,
            ),
          ),
          home: HomePage(
            fontFamily: settingsController.fontFamily,
            themeMode: settingsController.themeMode,
            initialPosition: lastPosition,
            onFontFamilyChange: (v) => settingsController.fontFamily = v,
            onThemeToggle: settingsController.toggleTheme,
          ),
        );
      },
    );
  }
}
