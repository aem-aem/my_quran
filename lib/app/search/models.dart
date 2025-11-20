class QuranSearchIndex {
  // Inverted index: word -> List of verse locations
  final Map<String, List<VerseLocation>> index = {};

  // Verse content cache for quick access
  final Map<String, String> verseCache = {};

  bool isInitialized = false;
}

class VerseLocation {
  // Word position in verse

  VerseLocation({
    required this.surah,
    required this.verse,
    required this.position,
  });

  factory VerseLocation.fromJson(Map<String, dynamic> json) => VerseLocation(
    surah: json['surah'] as int,
    verse: json['verse'] as int,
    position: json['position'] as int,
  );
  final int surah;
  final int verse;
  final int position;

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'verse': verse,
    'position': position,
  };
}

class SearchResult {
  SearchResult({
    required this.surah,
    required this.verse,
    required this.text,
    required this.matchPositions,
    required this.pageNumber,
  });
  final int surah;
  final int verse;
  final String text;
  final List<int> matchPositions; // Positions of matched words
  final int pageNumber;
}
