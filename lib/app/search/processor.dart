class ArabicTextProcessor {
  // Remove diacritics (tashkeel)
  static String removeDiacritics(String text) {
    return text.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
      '',
    );
  }

  // Normalize Arabic characters
  static String normalize(String text) {
    String normalized = removeDiacritics(text);

    // Normalize Alef variants: أ إ آ ا → ا
    normalized = normalized.replaceAll(RegExp('[أإآٱ]'), 'ا');

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
    if (text.isEmpty) return [];

    // Remove space after و if و is leading or preceded by space
    // Remove punctuation and extra spaces
    // then split by whitespace and filter empty
    return text
        .replaceAll(RegExp(r'(^|\s)و\s'), r'$1و')
        .replaceAll(
          RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
          ' ',
        )
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }
}
