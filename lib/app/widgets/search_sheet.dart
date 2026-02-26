import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/search/processor.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/quran/quran.dart';
import 'package:my_quran/app/search/models.dart';
import 'package:my_quran/app/services/search_service.dart';

class QuranSearchBottomSheet extends StatefulWidget {
  const QuranSearchBottomSheet({
    required this.verseFontFamily,
    required this.onNavigateToPage,
    super.key,
  });
  final void Function(int page, {int? surah, int? verse}) onNavigateToPage;
  final FontFamily verseFontFamily;
  @override
  State<QuranSearchBottomSheet> createState() => _QuranSearchBottomSheetState();
}

class _QuranSearchBottomSheetState extends State<QuranSearchBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  bool _isExactMatch = false;
  // Debounce timer to prevent search on every keystroke
  Timer? _debounce;
  Set<String> _currentQueryTokens = {};

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _currentQueryTokens = {};
      });
      return;
    }

    setState(() => _isSearching = true);

    final tokens = ArabicTextProcessor.prepareTextForSearchGrouped(query);
    _currentQueryTokens = tokens.expand((group) => group).toSet();

    // Pass the toggle value to the service
    final results = SearchService.search(query, exactMatch: _isExactMatch);

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(letterSpacing: 0),
              decoration: InputDecoration(
                hintText: 'ابحث عن آية...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onSearchChanged('');
                        },
                        onLongPress: () {},
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.applyOpacity(0.3),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // FILTER CHIP (Exact Match Toggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('إظهار النتائج المطابقة فقط'),
                  selected: _isExactMatch,
                  onSelected: (bool selected) {
                    setState(() {
                      _isExactMatch = selected;
                    });
                    // Re-run search immediately with new setting
                    _performSearch(_controller.text);
                  },

                  labelStyle: TextStyle(
                    color: _isExactMatch
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  selectedColor: colorScheme.primary,
                  checkmarkColor: colorScheme.onPrimary,
                ),

                if (_results.isNotEmpty) ...[
                  Expanded(
                    child: Text(
                      'عدد النتائج: ${_results.length}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // --- Results List ---
          Expanded(
            child:
                _results.isEmpty && _controller.text.isNotEmpty && !_isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (c, i) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return SearchResultItem(
                        verseFontFamily: widget.verseFontFamily,
                        queryTokens: _currentQueryTokens,
                        result: result,
                        highlightExactMatchOnly: _isExactMatch,
                        query: _controller.text,
                        onTap: () {
                          // 1. Close Sheet
                          Navigator.pop(context);

                          // 2. Calculate Page Number
                          final page = Quran.instance.getPageNumber(
                            result.surah,
                            result.verse,
                          );

                          // 3. Navigate with Highlight Info
                          widget.onNavigateToPage(
                            page,
                            surah: result.surah,
                            verse: result.verse,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SearchResultItem extends StatelessWidget {
  const SearchResultItem({
    required this.verseFontFamily,
    required this.result,
    required this.query,
    required this.onTap,
    required this.queryTokens,
    required this.highlightExactMatchOnly,
    super.key,
  });

  final SearchResult result;
  final Set<String> queryTokens;
  final bool highlightExactMatchOnly;
  final String query;
  final VoidCallback onTap;
  final FontFamily verseFontFamily;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Surah Name & Verse Number ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${Quran.instance.getSurahNameArabic(result.surah)} - '
                    '${result.verse}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: colorScheme.outline,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Body: Highlighted Verse Text ---
            _HighlightedText(
              debug: true,
              plainText: Quran.instance.getVerseInPlainText(
                result.surah,
                result.verse,
              ),
              displayText: Quran.instance.getVerse(result.surah, result.verse),
              query: query,
              queryTokens: queryTokens,
              highlightExactMatchOnly: highlightExactMatchOnly,
              highlightColor: colorScheme.primary,
              baseColor: colorScheme.onSurface,
              verseFontFamily: verseFontFamily,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.verseFontFamily,
    required this.plainText,
    required this.displayText,
    required this.query,
    required this.highlightColor,
    required this.baseColor,
    required this.queryTokens,
    required this.highlightExactMatchOnly,
    this.debug = false,
  });

  final String plainText;
  final String displayText;
  final String query;
  final Color highlightColor;
  final Color baseColor;
  final Set<String> queryTokens;
  final bool highlightExactMatchOnly;
  final FontFamily verseFontFamily;

  /// Enable to print mapping / matching diagnostics.
  final bool debug;

  // ---------------- Debug helpers ----------------
  void _d(String msg) {
    if (kDebugMode && debug) debugPrint(msg);
  }

  String _codepoints(String s) => s.runes
      .map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}')
      .join(' ');

  String _visible(String s) => s
      .replaceAll('\u00A0', '[NBSP]')
      .replaceAll('\u200F', '[RLM]')
      .replaceAll('\u200E', '[LRM]')
      .replaceAll('\u202A', '[LRE]')
      .replaceAll('\u202B', '[RLE]')
      .replaceAll('\u202C', '[PDF]')
      .replaceAll('\u202D', '[LRO]')
      .replaceAll('\u202E', '[RLO]')
      .replaceAll('\u2066', '[LRI]')
      .replaceAll('\u2067', '[RLI]')
      .replaceAll('\u2068', '[FSI]')
      .replaceAll('\u2069', '[PDI]');

  // ---------------- Tokenization / classification ----------------
  List<String> _splitWords(String s) =>
      s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

  String _stripBidi(String s) =>
      s.replaceAll(RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'), '');

  bool _containsPua(String s) => s.runes.any((r) => r >= 0xE000 && r <= 0xF8FF);

  String _stripQuranMarksAndHarakat(String s) {
    return s
        .replaceAll('\u0670', 'ا')
        // harakat (WITHOUT \u0670)
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        // Quran annotation marks (ۖ ۚ ۗ ۞ etc.)
        .replaceAll(RegExp(r'[\u06D6-\u06ED\u08D3-\u08FF]'), '')
        // end of ayah (if present)
        .replaceAll('\u06DD', '');
  }

  bool _hasArabicLetter(String s) {
    // Includes alef wasla (ٱ U+0671) + basic Arabic letters.
    return RegExp(r'[\u0621-\u064A\u0671]').hasMatch(s);
  }

  bool _isPlainWordToken(String token) {
    // A "real word" is any token that contains Arabic letters after removing marks.
    final t = _stripQuranMarksAndHarakat(token);
    return _hasArabicLetter(t);
  }

  bool _isDisplayWordToken(String token) {
    // Display text may be PUA glyph stream; treat PUA sequences as words.
    final t = _stripBidi(token).trim();
    if (t.isEmpty) return false;
    if (_containsPua(t)) return true;

    // Also support normal-unicode Arabic display.
    final stripped = _stripQuranMarksAndHarakat(t);
    return _hasArabicLetter(stripped);
  }

  // ---------------- Matching normalization ----------------
  String _normalizeForMatch(String s) {
    // 1) remove Quran marks/harakat that might appear in plain
    s = _stripQuranMarksAndHarakat(s);

    // 2) normalize your Arabic (alef forms etc.)
    s = ArabicTextProcessor.normalize(s);

    // 3) remove punctuation/non-letters around/inside token for matching
    s = s.replaceAll(RegExp(r'[^\u0600-\u06FF0-9]+'), '');

    // 4) make search equivalence match highlight equivalence:
    //    taa marbuta vs haa (then "ثمرة" highlights "ثمره")
    s = s.replaceAll(RegExp(r'ة$'), 'ه');

    return s;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ---- 1) Split tokens ----
    final plainTokens = _splitWords(plainText);

    // IMPORTANT: keep original display tokens (don’t strip bidi globally),
    // but drop tokens that are only bidi markers.
    final displayTokens = _splitWords(
      displayText,
    ).where((t) => _stripBidi(t).trim().isNotEmpty).toList();

    // ---- 2) Filter plain to content-words only (skip ۞ ۖ ۚ ۗ etc) ----
    final plainContentWords = <String>[];
    for (int i = 0; i < plainTokens.length; i++) {
      final t = plainTokens[i];
      final isWord = _isPlainWordToken(t);
      if (!isWord) {
        _d('PLAIN SKIP i=$i "${_visible(t)}" cps=${_codepoints(t)}');
      } else {
        plainContentWords.add(t);
      }
    }

    // ---- 3) Normalize query tokens the SAME way highlight does ----
    // (Union: use passed queryTokens + split(query) as a fallback)
    final rawQueryTokens = <String>{...queryTokens, ..._splitWords(query)};

    final normalizedQueryTokens = rawQueryTokens
        .map(_normalizeForMatch)
        .where((t) => t.isNotEmpty)
        .toSet();

    bool matches(String normalizedPlainWord) {
      if (normalizedPlainWord.isEmpty || normalizedQueryTokens.isEmpty) {
        return false;
      }

      if (highlightExactMatchOnly) {
        return normalizedQueryTokens.contains(normalizedPlainWord);
      } else {
        for (final q in normalizedQueryTokens) {
          if (normalizedPlainWord.startsWith(q)) return true;
        }
        return false;
      }
    }

    _d('QUERY normalized tokens = $normalizedQueryTokens');

    // ---- 4) Build display->plain mapping (consume only display "word tokens") ----
    final displayToPlain = <int?>[];
    int p = 0;
    int displayWordCount = 0;

    for (int d = 0; d < displayTokens.length; d++) {
      final dt = displayTokens[d];
      final isWord = _isDisplayWordToken(dt);

      if (isWord) {
        displayWordCount++;
        displayToPlain.add(p < plainContentWords.length ? p : null);
        p++;
      } else {
        displayToPlain.add(null);
      }
    }

    _d(
      'COUNTS: plainTokens=${plainTokens.length}, '
      'plainContentWords=${plainContentWords.length}, '
      'displayTokens=${displayTokens.length}, '
      'displayWordCount=$displayWordCount',
    );

    if (displayWordCount != plainContentWords.length) {
      _d(
        'WARNING: word-count mismatch -> alignment may drift.\n'
        '  displayWordCount=$displayWordCount vs plainContentWords=${plainContentWords.length}',
      );
    }

    // ---- 5) Find first match in PLAIN content words ----
    int firstMatchPlainIndex = -1;
    for (int i = 0; i < plainContentWords.length; i++) {
      final norm = _normalizeForMatch(plainContentWords[i]);
      if (matches(norm)) {
        firstMatchPlainIndex = i;
        break;
      }
    }

    // Convert to DISPLAY index
    int firstMatchDisplayIndex = -1;
    if (firstMatchPlainIndex != -1) {
      firstMatchDisplayIndex = displayToPlain.indexWhere(
        (m) => m == firstMatchPlainIndex,
      );
    }

    _d(
      'MATCH: firstMatchPlainIndex=$firstMatchPlainIndex '
      '-> firstMatchDisplayIndex=$firstMatchDisplayIndex',
    );

    if (firstMatchPlainIndex == -1) {
      // Very useful when you see results but no highlight:
      // it means your normalization still differs from search.
      _d(
        'NO MATCH FOUND. Sample normalized plain words (first 25): '
        '${plainContentWords.take(25).map(_normalizeForMatch).toList()}',
      );
    }

    // ---- 6) Decide slicing based on DISPLAY indices (since we render display) ----
    int startDisplayIndex = 0;
    bool showStartEllipsis = false;

    if (firstMatchDisplayIndex > 10) {
      startDisplayIndex = firstMatchDisplayIndex - 3;
      showStartEllipsis = true;
    }

    final slicedDisplayTokens = displayTokens.sublist(startDisplayIndex);
    final slicedMap = displayToPlain.sublist(startDisplayIndex);

    // Keep old behavior but safer: only trim trailing non-word display tokens.
    if (verseFontFamily == FontFamily.hafs) {
      while (slicedDisplayTokens.isNotEmpty &&
          !_isDisplayWordToken(slicedDisplayTokens.last)) {
        slicedDisplayTokens.removeLast();
        slicedMap.removeLast();
      }
    }

    final isWarsh = verseFontFamily == FontFamily.warsh;

    return RichText(
      textDirection: TextDirection.rtl,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: isWarsh ? 26 : 20,
          color: baseColor,
          height: 1.8,
          fontWeight: isWarsh ? FontWeight.w500 : null,
          fontFamily: verseFontFamily.name,
          letterSpacing: 0,
        ),
        children: [
          if (showStartEllipsis)
            TextSpan(
              text: '... ',
              style: TextStyle(color: baseColor.withOpacity(0.8)),
            ),
          ...List.generate(slicedDisplayTokens.length, (i) {
            final displayTok = slicedDisplayTokens[i];
            final plainIndex = slicedMap[i];

            bool isMatch = false;
            if (plainIndex != null && plainIndex < plainContentWords.length) {
              final norm = _normalizeForMatch(plainContentWords[plainIndex]);
              isMatch = matches(norm);
            }

            return TextSpan(
              text: '$displayTok ',
              style: isMatch
                  ? TextStyle(
                      backgroundColor: highlightColor,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }
}
