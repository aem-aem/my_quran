import 'dart:convert';

class ArabicTextProcessor {
  static Map<String, List<String>>? _spellVariants;

  // Initialize the processor by loading spell variants
  static void initialize(String jsonString) {
    if (_spellVariants != null) return;
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // Build a map where each key maps to a list of values
    final Map<String, List<String>> variants = {};
    for (final entry in decoded.entries) {
      final key = entry.key;
      final value = entry.value;
      // Handle both String and List<String> values from JSON
      if (value is String) {
        variants.putIfAbsent(key, () => []).add(value);
      } else if (value is List) {
        variants[key] = value.cast<String>();
      }
    }
    print('🔤 Loaded ${variants.length} spell variants');
    _spellVariants = variants;
  }

  /// Normalize Arabic characters by removing diacritics and marks
  static String normalize(String text) {
    // Remove diacritics and Quranic annotation marks:
    // \u200E-\u200F: LRM/RLM (bidirectional formatting)
    // \u0610-\u061A: Arabic Koranic Annotation Signs
    // \u0640: Tatweel (Kashida)
    // \u064B-\u065F: Standard diacritics (tashkeel)
    // \u0660-\u0669: Eastern Arabic-Indic digits
    // \u0670: Superscript Alef (dagger alef)
    // \u06D6-\u06ED: Quranic marks
    // \u06F0-\u06F9: Extended Arabic-Indic digits (Persian)
    var normalized = text.replaceAll(
      RegExp(r'[\u200E\u200F\u0610-\u061A\u0640\u064B-\u065F\u0660-\u0669\u0670\u06D6-\u06F9]'),
      '',
    );

    // Replace Alef Wasla (ٱ) with regular Alef (ا)
    normalized = normalized.replaceAll('\u0671', '\u0627');

    return normalized.trim();
  }

  /// Tokenize Arabic text into words
  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];

    // Remove punctuation and extra spaces
    // then split by whitespace and filter empty
    return text
        .replaceAll(
          RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
          ' ',
        )
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Returns a list of word groups, where each group contains the normalized word
  /// and its spell variants. Used for search where variants should be OR'd together.
  static List<List<String>> prepareTextForSearchGrouped(String text) {
    final tokens = tokenize(text);
    final List<List<String>> wordGroups = [];

    for (final token in tokens) {
      final normalized = normalize(token);
      if (normalized.isEmpty) continue;

      final List<String> group = [normalized];
      // Add spell variants if they exist
      if (_spellVariants != null && _spellVariants!.containsKey(normalized)) {
        group.addAll(_spellVariants![normalized]!);
      }
      wordGroups.add(group);
    }

    return wordGroups;
  }
}
