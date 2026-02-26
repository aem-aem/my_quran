// ignore_for_file: avoid_print (needed for debugging)

/*
# quran.json contains the Uthmani script Quran text
*/

import 'dart:convert';
import 'dart:io';

import 'package:my_quran/app/search/processor.dart';

/// Generates the search index for the Quran text
/// Run with: dart run lib/tools/search_index_generator.dart
void main() async {
  print('🔨 Building search index...');

  // Load Quran data from both files
  final quranFile = File('./assets/quran.json');
  if (!quranFile.existsSync()) {
    print('❌ Error: assets/quran.json not found');
    exit(1);
  }

  final quranData =
      jsonDecode(await quranFile.readAsString()) as Map<String, dynamic>;

  // Build inverted index
  // Map<normalized_word, Set<verse_id>>
  final Map<String, Set<int>> invertedIndex = {};

  for (final surahEntry in quranData.entries) {
    final surahNumber = int.parse(surahEntry.key);
    final verses = surahEntry.value as Map<String, dynamic>;

    for (final verseEntry in verses.entries) {
      final verseNumber = int.parse(verseEntry.key);
      final text = verseEntry.value as String;

      // Create unique verse ID: surah * 1000 + verse
      final verseId = surahNumber * 1000 + verseNumber;

      // Process verse text
      _processVerseText(text, verseId, invertedIndex);
    }
  }

  // Sort keys for binary search optimization
  final sortedKeys = invertedIndex.keys.toList()..sort();

  // Convert sets to lists for JSON
  final indexData = <String, List<int>>{};
  for (final key in sortedKeys) {
    indexData[key] = invertedIndex[key]!.toList()..sort();
  }

  // Create final output
  final output = {'keys': sortedKeys, 'data': indexData};

  // Write to file
  final outputFile = File('assets/search_index.json');
  await outputFile.writeAsString(jsonEncode(output));

  print('✅ Search index generated successfully!');
  print('📊 Total unique words: ${sortedKeys.length}');
  print('📝 Output: ${outputFile.path}');
}

/// Process verse text and add to inverted index
void _processVerseText(
  String text,
  int verseId,
  Map<String, Set<int>> invertedIndex,
) {
  // Tokenize and normalize using pure Dart utils
  final tokens = ArabicTextProcessor.tokenize(text);

  for (final token in tokens) {
    final normalized = ArabicTextProcessor.normalize(token);
    if (normalized.isNotEmpty) {
      invertedIndex.putIfAbsent(normalized, () => <int>{});
      invertedIndex[normalized]!.add(verseId);
    }
  }
}
