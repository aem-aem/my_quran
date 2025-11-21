import 'package:flutter/foundation.dart' show debugPrint;
import 'package:my_quran/app/search/models.dart';
import 'package:my_quran/app/search/processor.dart';
import 'package:quran/quran.dart' as quran;

class QuranSearchEngine {
  QuranSearchEngine(this._index);
  final QuranSearchIndex _index;

  Future<List<SearchResult>> search(
    String query, {
    int maxResults = 50,
    bool exactMatch = false,
  }) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = ArabicTextProcessor.normalize(query);
    final queryWords = ArabicTextProcessor.tokenize(normalizedQuery);

    if (queryWords.isEmpty) return [];

    debugPrint('🔍 Searching for: $queryWords');

    if (exactMatch || queryWords.length > 1) {
      return _phraseSearch(queryWords, maxResults);
    } else {
      return _singleWordSearch(queryWords.first, maxResults);
    }
  }

  List<SearchResult> _singleWordSearch(String word, int maxResults) {
    final locations = _index.index[word] ?? [];
    final results = <SearchResult>[];

    for (final location in locations.take(maxResults)) {
      final verseKey = '${location.surah}:${location.verse}';
      final verseText =
          _index.verseCache[verseKey] ??
          quran.getVerse(location.surah, location.verse);

      results.add(
        SearchResult(
          surah: location.surah,
          verse: location.verse,
          text: verseText,
          matchPositions: [location.position],
          pageNumber: quran.getPageNumber(location.surah, location.verse),
        ),
      );
    }

    return results;
  }

  List<SearchResult> _phraseSearch(List<String> words, int maxResults) {
    // Find verses containing all words
    final firstWordLocations = _index.index[words.first] ?? [];
    final candidateVerses = <String, List<int>>{};

    // Collect all verses containing the first word
    for (final loc in firstWordLocations) {
      final key = '${loc.surah}:${loc.verse}';
      candidateVerses[key] ??= [];
      candidateVerses[key]!.add(loc.position);
    }

    final results = <SearchResult>[];

    // Check each candidate verse
    for (final entry in candidateVerses.entries) {
      final parts = entry.key.split(':');
      final surah = int.parse(parts[0]);
      final verse = int.parse(parts[1]);

      final verseText =
          _index.verseCache[entry.key] ?? quran.getVerse(surah, verse);
      final verseWords = ArabicTextProcessor.tokenize(verseText);

      // Check if phrase exists in sequence
      final matchPositions = _findPhrasePositions(verseWords, words);

      if (matchPositions.isNotEmpty) {
        results.add(
          SearchResult(
            surah: surah,
            verse: verse,
            text: verseText,
            matchPositions: matchPositions,
            pageNumber: quran.getPageNumber(surah, verse),
          ),
        );

        if (results.length >= maxResults) break;
      }
    }

    return results;
  }

  List<int> _findPhrasePositions(
    List<String> verseWords,
    List<String> searchWords,
  ) {
    final positions = <int>[];

    for (int i = 0; i <= verseWords.length - searchWords.length; i++) {
      bool match = true;

      for (int j = 0; j < searchWords.length; j++) {
        if (verseWords[i + j] != searchWords[j]) {
          match = false;
          break;
        }
      }

      if (match) {
        positions.addAll(List.generate(searchWords.length, (j) => i + j));
      }
    }

    return positions;
  }

  // Fuzzy search (optional - for typo tolerance)
  List<SearchResult> fuzzySearch(String query, {int maxResults = 20}) {
    // Implementation using Levenshtein distance or similar
    // This is more advanced - can be added later
    return [];
  }
}
