// ignore_for_file: avoid_print (needed for debugging)

/*
# quran-simple-clean.txt comes from https://tanzil.net/download/
# Quran text type : Simple (Clean)
# Output file format : Text (with aya numbers)
# Do not inlucde pause marks, nor sajdah signs, nor rub-el-hizb signs
# Remove basmalah from the first aya of each sourah except Fatiha
# Then convert to JSON format.
*/

import 'dart:convert';
import 'dart:io';

import 'package:my_quran/app/search/processor.dart';

/// Generates the search index for the Quran text
/// Run with: dart run search_index_generator.dart
void main() async {
  print('🔨 Building search index...');

  // Load Quran data from both files
  final quranFile = File('./assets/quran.json');
  if (!quranFile.existsSync()) {
    print('❌ Error: assets/quran.json not found');
    exit(1);
  }

  final quranSimpleFile = File('./lib/tools/quran_simple_clean.json');
  if (!quranSimpleFile.existsSync()) {
    print('❌ Error: quran_simple_clean.json not found');
    exit(1);
  }

  final quranData =
      jsonDecode(await quranFile.readAsString()) as Map<String, dynamic>;
  final quranSimpleData =
      jsonDecode(await quranSimpleFile.readAsString()) as Map<String, dynamic>;

  // Build inverted index
  // Map<normalized_word, Set<verse_id>>
  final Map<String, Set<int>> invertedIndex = {};

  for (final surahEntry in quranData.entries) {
    final surahNumber = int.parse(surahEntry.key);
    final verses = surahEntry.value as Map<String, dynamic>;
    final versesSimple =
        quranSimpleData[surahEntry.key] as Map<String, dynamic>?;

    for (final verseEntry in verses.entries) {
      final verseNumber = int.parse(verseEntry.key);
      final text = verseEntry.value as String;
      final textSimple = versesSimple?[verseEntry.key] as String?;

      // Create unique verse ID: surah * 1000 + verse
      final verseId = surahNumber * 1000 + verseNumber;

      // Process primary transcription
      _processVerseText(text, verseId, invertedIndex);

      // Process simple transcription
      if (textSimple != null) {
        _processVerseText(textSimple, verseId, invertedIndex);
      }
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
  // We use the processor's tokenizer, as it only removes punctuation.
  final tokens = ArabicTextProcessor.tokenize(text);

  for (final token in tokens) {
    final Set<String> variantsToNormalize = {};

    // If the raw token contains a dagger alef...
    if (token.contains('\u0670')) {
      // ...generate a variant with it replaced by a standard alef...
      variantsToNormalize.add(token.replaceAll('\u0670', 'ا'));
      // ...and a variant with it simply removed.
      variantsToNormalize.add(token.replaceAll('\u0670', ''));
    } else {
      // Otherwise, just process the token as is.
      variantsToNormalize.add(token);
    }

    // Normalize and index all generated variants
    for (final variant in variantsToNormalize) {
      final normalized = _normalizeBase(variant); // Using the local function
      if (normalized.isNotEmpty) {
        invertedIndex.putIfAbsent(normalized, () => <int>{});
        invertedIndex[normalized]!.add(verseId);
      }
    }
  }
}

String _normalizeBase(String text) {
  // Remove punctuation and symbols
  String normalized = text.replaceAll(
    RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
    '',
  );

  // Remove all diacritics (including dagger alef, without replacement)
  normalized = normalized.replaceAll(
    RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
    '',
  );

  // Normalize Alef variants: أ إ آ ا → ا
  normalized = normalized.replaceAll(RegExp('[أإآٱ]'), 'ا');

  // Normalize Taa Marbuta: ة → ه
  normalized = normalized.replaceAll('ة', 'ه');

  // Normalize Alef Maksura: ى → ي
  normalized = normalized.replaceAll('ى', 'ي');

  // Normalize Hamza forms
  normalized = normalized.replaceAll('ؤ', 'و');
  normalized = normalized.replaceAll('ئ', 'ء');
  normalized = normalized.replaceAll('ء', '');

  // Remove Tatweel (kashida)
  normalized = normalized.replaceAll('ـ', '');

  return normalized.trim();
}
