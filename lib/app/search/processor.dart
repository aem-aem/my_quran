import 'dart:convert';
import 'package:flutter/services.dart';

class ArabicTextProcessor {
  static Map<String, String>? _spellVariants;

  static Future<void> _loadSpellVariants() async {
    if (_spellVariants != null) return;
    final jsonString = await rootBundle.loadString('lib/tools/uthmani_to_simple.json');
    _spellVariants = jsonDecode(jsonString) as Map<String, String>;
  }

  // Initialize the processor by loading spell variants
  static Future<void> initialize() async {
    await _loadSpellVariants();
  }

  // Remove diacritics (tashkeel)
  static String removeDiacritics(String text) {
    // Convert dagger alef to standard alef for consistency.
    text = text.replaceAll('\u0670', 'ا');
    return text.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED]'),
      '',
    );
  }

  // Normalize Arabic characters
  static String normalize(String text) {
    // Apply special spelling variants first for user-typed queries.
    String normalized = _spellVariants?[text] ?? text;

    // Remove punctuation and symbols
    normalized = normalized.replaceAll(
      RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
      '',
    );
    normalized = removeDiacritics(normalized);

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

  // Tokenize Arabic text into words
  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];

    // Remove space after و if و is leading or preceded by space
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
}
