import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:my_quran/app/search/models.dart';
import 'package:my_quran/app/search/processor.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

class QuranSearchIndexBuilder {
  static Future<QuranSearchIndex> buildIndex() async {
    final index = QuranSearchIndex();

    debugPrint('🔨 Building Quran search index...');
    final stopwatch = Stopwatch()..start();

    // Iterate through all verses
    for (int surah = 1; surah <= 114; surah++) {
      final verseCount = quran.getVerseCount(surah);

      for (int verse = 1; verse <= verseCount; verse++) {
        final verseText = quran.getVerse(surah, verse);
        final verseKey = '$surah:$verse';

        // Cache verse text
        index.verseCache[verseKey] = verseText;

        // Tokenize and index
        final words = ArabicTextProcessor.tokenize(verseText);

        for (int position = 0; position < words.length; position++) {
          final word = words[position];

          // Add to inverted index
          index.index[word] ??= [];
          index.index[word]!.add(
            VerseLocation(surah: surah, verse: verse, position: position),
          );

          // Also add variations
          for (var variation in ArabicTextProcessor.getVariations(word)) {
            if (variation != word) {
              index.index[variation] ??= [];
              index.index[variation]!.add(
                VerseLocation(surah: surah, verse: verse, position: position),
              );
            }
          }
        }
      }

      // Progress indicator
      if (surah % 10 == 0) {
        debugPrint('Indexed $surah/114 surahs');
      }
    }

    stopwatch.stop();
    debugPrint('✅ Index built in ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('📊 Total unique words: ${index.index.length}');

    index.isInitialized = true;
    return index;
  }

  // Save index to local storage
  static Future<void> saveIndex(QuranSearchIndex index) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert index to JSON
    final indexJson = <String, dynamic>{};

    index.index.forEach((word, locations) {
      indexJson[word] = locations.map((loc) => loc.toJson()).toList();
    });

    final indexString = jsonEncode({
      'index': indexJson,
      'verseCache': index.verseCache,
      'version': 1, // For future migrations
    });

    await prefs.setString('quran_searchindex', indexString);
    debugPrint('💾 Index saved to local storage');
  }

  // Load index from local storage
  static Future<QuranSearchIndex?> loadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final indexString = prefs.getString('quran_searchindex');

    if (indexString == null) return null;

    try {
      final data = jsonDecode(indexString) as Map<String, dynamic>;
      final index = QuranSearchIndex();

      // Load inverted index
      final indexJson = data['index'] as Map<String, dynamic>;
      indexJson.forEach((word, locations) {
        index.index[word] = (locations as List)
            .map((loc) => VerseLocation.fromJson(loc as Map<String, dynamic>))
            .toList();
      });

      // Load verse cache
      final cacheJson = data['verseCache'] as Map<String, dynamic>;
      cacheJson.forEach((key, value) {
        index.verseCache[key] = value as String;
      });

      index.isInitialized = true;
      debugPrint('✅ Index loaded from storage');
      return index;
    } catch (e) {
      debugPrint('❌ Failed to load index: $e');
      return null;
    }
  }
}
