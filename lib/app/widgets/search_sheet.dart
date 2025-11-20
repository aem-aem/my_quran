import 'dart:async';

import 'package:flutter/material.dart';

import 'package:quran/quran.dart' as quran;

import 'package:my_quran/app/search/models.dart';
import 'package:my_quran/app/search/processor.dart';
import 'package:my_quran/app/services/search_service.dart';

class QuranSearchBottomSheet extends StatefulWidget {
  const QuranSearchBottomSheet({required this.onNavigateToPage, super.key});
  final void Function(int page) onNavigateToPage;

  @override
  State<QuranSearchBottomSheet> createState() => _QuranSearchBottomSheetState();
}

class _QuranSearchBottomSheetState extends State<QuranSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 500);
  @override
  void initState() {
    super.initState();

    // Auto-search as user types (debounced)
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();

    setState(() {}); // Update UI for clear button

    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final searchService = SearchService();
      final results = await searchService.search(query, maxResults: 100);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في البحث: $e')));
      }
    }
  }

  void _onResultTap(SearchResult result) {
    widget.onNavigateToPage(result.pageNumber);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return SizedBox(
      height: mediaQuery.size.height,
      child: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث عن آية أو كلمة...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Update clear button visibility
              },
              onSubmitted: _performSearch,
            ),
          ),
          const Divider(),

          // Results
          Expanded(child: _buildResultsSection(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildResultsSection(ColorScheme colorScheme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'ابحث عن آية أو كلمة',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب كلمات مختلفة',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'عدد النتائج: ${_searchResults.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _SearchResultTile(
                result: result,
                searchQuery: _searchController.text,
                onTap: () => _onResultTap(result),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });
  final SearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Surah name and page
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${quran.getSurahNameArabic(result.surah)} - '
                      '${result.verse}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'صفحة ${result.pageNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Verse text with highlighted matches
              _buildHighlightedText(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedQuery = ArabicTextProcessor.normalize(searchQuery);
    final queryWords = ArabicTextProcessor.tokenize(normalizedQuery);

    // Split verse into words
    final verseWords = result.text.split(RegExp(r'\s+'));
    final normalizedVerseWords = verseWords
        .map(ArabicTextProcessor.normalize)
        .toList();

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      text: TextSpan(
        style: TextStyle(
          fontSize: 18,
          height: 1.8,
          color: colorScheme.onSurface,
          fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
        ),
        children: verseWords.asMap().entries.map((entry) {
          final index = entry.key;
          final word = entry.value;
          final normalizedWord = normalizedVerseWords[index];

          // Check if this word matches any query word
          final isMatch = queryWords.any(normalizedWord.contains);

          return TextSpan(
            text: '$word ',
            style: isMatch
                ? TextStyle(
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}
