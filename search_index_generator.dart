// index_generator.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
// You might need to temporarily copy your ArabicTextProcessor logic
// into this file if you can't import it easily from 'lib'.

void main() async {
  print('🔨 Pre-calculating Search Index...');

  // 1. Read the quran.json we created earlier
  final quranFile = File('assets/quran.json');
  final String jsonString = await quranFile.readAsString();
  final Map<String, dynamic> quranData =
      jsonDecode(jsonString) as Map<String, dynamic>;

  // The Index: Map<Word, List<LocationInt>>
  // LocationInt = (Surah * 1000) + Verse
  final Map<String, List<int>> invertedIndex = {};

  quranData.forEach((surahKey, versesMap) {
    final surah = int.parse(surahKey);
    (versesMap as Map).forEach((verseKey, text) {
      final verse = int.parse(verseKey.toString());

      final words = ArabicTextProcessor.tokenize(text.toString());

      for (final word in words) {
        // Normalize word
        final cleanWord = ArabicTextProcessor.normalize(word);
        if (cleanWord.isEmpty) continue;

        if (!invertedIndex.containsKey(cleanWord)) {
          invertedIndex[cleanWord] = [];
        }

        // Encode location: 2005 = Surah 2, Verse 5
        final locationId = (surah * 1000) + verse;

        // Avoid duplicates for same verse
        if (!invertedIndex[cleanWord]!.contains(locationId)) {
          invertedIndex[cleanWord]!.add(locationId);
        }
      }
    });
  });

  // 2. Sort keys for Binary Search capability (Prefix search)
  // This is crucial for fast "starts with" searching
  final sortedKeys = invertedIndex.keys.toList()..sort();

  final Map<String, dynamic> finalOutput = {
    'keys': sortedKeys,
    'data': invertedIndex,
  };

  // 3. Save to asset
  final outputFile = File('assets/search_index.json');
  await outputFile.writeAsString(jsonEncode(finalOutput));

  print('✅ Index generated at assets/search_index.json');
  print('Word count: ${sortedKeys.length}');
}

class ArabicTextProcessor {
  // Remove diacritics (tashkeel)
  static String removeDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  // Normalize Arabic characters
  static String normalize(String text) {
    String normalized = removeDiacritics(text);

    // Normalize Alef variants: أ إ آ ا → ا
    normalized = normalized.replaceAll(RegExp('[أإآ]'), 'ا');

    // Normalize Taa Marbuta: ة → ه
    normalized = normalized.replaceAll('ة', 'ه');

    // Normalize Alef Maksura: ى → ي
    normalized = normalized.replaceAll('ى', 'ي');

    // Remove Tatweel (kashida)
    normalized = normalized.replaceAll('ـ', '');

    return normalized.trim();
  }

  // Tokenize Arabic text into words
  static List<String> tokenize(String text) {
    // Remove punctuation and extra spaces
    // then split by whitespace and filter empty
    return text
        .replaceAll(RegExp(r'[۞۩،؛؟\.\,\!\?\:\;]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  // Get root variations for better search (optional - advanced)
  static List<String> getVariations(String word) {
    final variations = <String>[word];

    // Add version with/without ال (the definite article)
    if (word.startsWith('ال') && word.length > 2) {
      variations.add(word.substring(2));
    } else {
      variations.add('ال$word');
    }

    return variations;
  }
}
