import 'package:flutter/foundation.dart';
import 'package:my_quran/app/search/engine.dart';
import 'package:my_quran/app/search/index_builder.dart';
import 'package:my_quran/app/search/models.dart';

class SearchService {
  factory SearchService() => _instance;
  SearchService._internal();
  static final SearchService _instance = SearchService._internal();

  QuranSearchIndex? _index;
  QuranSearchEngine? _engine;

  bool get isReady => _index?.isInitialized ?? false;

  Future<void> initialize() async {
    if (isReady) return;

    debugPrint('🚀 Initializing Quran search service...');

    // Try to load from cache
    _index = await QuranSearchIndexBuilder.loadIndex();

    // If not cached, build new index
    if (_index == null) {
      _index = await QuranSearchIndexBuilder.buildIndex();
      await QuranSearchIndexBuilder.saveIndex(_index!);
    }

    _engine = QuranSearchEngine(_index!);
    debugPrint('✅ Search service ready');
  }

  Future<List<SearchResult>> search(
    String query, {
    int maxResults = 50,
    bool exactMatch = false,
  }) async {
    if (!isReady) {
      await initialize();
    }

    return _engine!.search(
      query,
      maxResults: maxResults,
      exactMatch: exactMatch,
    );
  }
}
