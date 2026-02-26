import 'package:collection/collection.dart';
import 'package:my_quran/app/search/models.dart';
import 'package:my_quran/app/search/processor.dart';
import 'package:my_quran/app/services/conditional_import/import.dart';

class SearchService {
  static List<String> _sortedKeys = [];

  static Map<String, dynamic> _indexData = {};

  // Track current loaded type to avoid reloading the same file
  static String _currentType = '';
  static bool isReady = false;

  /// Initialize or Switch Index
  /// [fontFamily]: 'hafs', 'warsh', 'rustam', etc.
  static Future<void> init(String fontFamily) async {
    // Determine target file
    String targetFile;
    if (fontFamily.toLowerCase() == 'warsh') {
      targetFile = 'assets/search_index_warsh.json';
    } else {
      // Default to Hafs for 'hafs', 'rustam', or anything else
      targetFile = 'assets/search_index_hafs.json';
    }

    // Optimization: Don't reload if we already have this index
    if (isReady && _currentType == targetFile) return;

    isReady = false;
    _currentType = targetFile;

    try {
      final jsonString = await loadAsset(targetFile);
      final data = await decodeJson(jsonString) as Map<String, dynamic>;

      _sortedKeys = (data['keys'] as List).cast<String>();
      _indexData = data['data'] as Map<String, dynamic>;

      final spellingVariantsString = await loadAsset('assets/simple_to_uthmani.json');
      // Load spell variants for search normalization
      ArabicTextProcessor.initialize(spellingVariantsString);

      isReady = true;
      debugLog('🔍 Search index and spell variants loaded ✅');
    } catch (e) {
      debugLog('❌ Error loading search index: $e');
      isReady = false;
    }
  }

  static List<SearchResult> search(String rawQuery, {bool exactMatch = false}) {
    if (!isReady || rawQuery.trim().isEmpty) return [];

    // Get words grouped with their variants
    final wordGroups = ArabicTextProcessor.prepareTextForSearchGrouped(rawQuery);
    debugLog('📝 Word groups: $wordGroups');

    if (wordGroups.isEmpty) return [];

    final List<Set<int>> matchesPerWord = [];

    for (final group in wordGroups) {
      // Union all variants for a single input word
      final Set<int> matchesForThisWord = {};
      for (final variant in group) {
        matchesForThisWord.addAll(_findMatchesForSingleToken(
          variant,
          exactMatch: exactMatch,
        ));
      }
      if (matchesForThisWord.isEmpty) return [];
      matchesPerWord.add(matchesForThisWord);
    }

    // Intersection across different input words
    Set<int> finalIds = matchesPerWord[0];
    for (int i = 1; i < matchesPerWord.length; i++) {
      finalIds = finalIds.intersection(matchesPerWord[i]);
    }

    final results = finalIds.map((id) {
      final surah = id ~/ 1000;
      final verse = id % 1000;
      return SearchResult(surah: surah, verse: verse);
    }).toList();

    results.sort((a, b) {
      if (a.surah != b.surah) return a.surah.compareTo(b.surah);
      return a.verse.compareTo(b.verse);
    });

    return results;
  }

  static Set<int> _findMatchesForSingleToken(
    String token, {
    bool exactMatch = false,
  }) {
    final Set<int> results = {};

    // 1. Exact Match
    if (_indexData.containsKey(token)) {
      final list = _indexData[token] as List;
      results.addAll(list.cast<int>());
    }

    // 2. Prefix Match (if enabled)
    if (!exactMatch) {
      // Find the first key that is not smaller than the
      // token using binary search
      final startIndex = lowerBound(_sortedKeys, token);

      // Iterate from the start index as long as keys start with the token
      for (int i = startIndex; i < _sortedKeys.length; i++) {
        final key = _sortedKeys[i];
        if (key.startsWith(token)) {
          // Avoid adding the exact match twice
          if (key != token && _indexData.containsKey(key)) {
            final list = _indexData[key] as List;
            results.addAll(list.cast<int>());
          }
        } else {
          // Since the list is sorted, we can stop as soon as we find a key
          // that doesn't start with the token.
          break;
        }
      }
    }

    return results;
  }
}
