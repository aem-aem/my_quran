import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:quran/quran.dart' as quran;

import 'package:my_quran/app/pages/bookmarks_page.dart';
import 'package:my_quran/app/services/reading_position_service.dart';
import 'package:my_quran/app/widgets/settings_sheet.dart';
import 'package:my_quran/app/widgets/verse_menu_overlay.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/widgets/floating_bottom_bar.dart';
import 'package:my_quran/app/widgets/navigation_sheet.dart';
import 'package:my_quran/app/widgets/search_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onThemeToggle,
    required this.onFontFamilyChange,
    required this.fontFamily,
    required this.themeMode,
    this.initialPosition,
    super.key,
  });
  final VoidCallback onThemeToggle;
  final ValueChanged<String> onFontFamilyChange;
  final ReadingPosition? initialPosition;
  final ThemeMode themeMode;
  final String fontFamily;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final ScrollController _scrollController;
  Timer? savePositionTimer;
  final int _totalPages = quran.totalPagesCount;
  final Map<int, GlobalKey> _pageKeys = {};

  // Or for compact version:
  final GlobalKey<FloatingBottomBarState> _bottomBarKey = GlobalKey();

  ScrollDirection _lastScrollDirection = ScrollDirection.idle;
  int _loadedStartPage = 1;
  int _loadedEndPage = 5;
  final int _loadMoreThreshold = 3;

  // Current position tracking
  final ValueNotifier<ReadingPosition> _currentPositionNotifier = ValueNotifier(
    const ReadingPosition(
      pageNumber: 1,
      surahNumber: 1,
      verseNumber: 1,
      juzNumber: 1,
    ),
  );

  ReadingPosition get _currentPosition => _currentPositionNotifier.value;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    if (widget.initialPosition != null) {
      _currentPositionNotifier.value = widget.initialPosition!;
      _jumpToPage(_currentPosition.pageNumber);
    }
  }

  @override
  void dispose() {
    // Save position before disposing
    ReadingPositionService.savePosition(_currentPosition);

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _scrollController.dispose();
    _currentPositionNotifier.dispose();
    super.dispose();
  }

  // Listen to app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App going to background
        debugPrint('📱 App paused - saving position');
        ReadingPositionService.savePosition(_currentPosition);

      case AppLifecycleState.detached:
        // App being terminated
        debugPrint('📱 App detached - saving position');
        ReadingPositionService.savePosition(_currentPosition);
      // ignore: no_default_cases
      default:
        break;
    }
  }

  void _onScroll() {
    _updateCurrentPosition();
    _handleLazyLoading();

    _handleBottomBarVisibility();
  }

  void _handleBottomBarVisibility() {
    if (!_scrollController.hasClients) return;

    final currentDirection = _scrollController.position.userScrollDirection;

    // Hide on scroll down, show on scroll up
    if (currentDirection == ScrollDirection.reverse &&
        _lastScrollDirection != ScrollDirection.reverse) {
      _bottomBarKey.currentState?.hide();
    } else if (currentDirection == ScrollDirection.forward &&
        _lastScrollDirection != ScrollDirection.forward) {
      _bottomBarKey.currentState?.show();
    }

    _lastScrollDirection = currentDirection;
  }

  void _updateCurrentPosition() {
    if (!_scrollController.hasClients) return;

    final scrollPosition = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final centerOfViewport = scrollPosition + (viewportHeight / 2);

    for (var pageNum = _loadedStartPage; pageNum <= _loadedEndPage; pageNum++) {
      final pageKey = _pageKeys[pageNum];
      if (pageKey?.currentContext == null) continue;

      final renderBox =
          pageKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      final pagePosition = renderBox.localToGlobal(Offset.zero);
      final pageTop = scrollPosition + pagePosition.dy;
      final pageHeight = renderBox.size.height;
      final pageBottom = pageTop + pageHeight;

      if (centerOfViewport >= pageTop && centerOfViewport <= pageBottom) {
        // Calculate approximate position within page
        final positionInPage = (centerOfViewport - pageTop) / pageHeight;
        _setPositionForPage(pageNum, positionInPage);
        break;
      }
    }
  }

  void _setPositionForPage(int pageNum, double positionInPage) {
    final pageData = quran.getPageData(pageNum);
    if (pageData.isEmpty) return;

    // Calculate total verses on page
    int totalVerses = 0;
    for (final surahData in pageData) {
      final start = surahData['start'] as int;
      final end = surahData['end'] as int;
      totalVerses += end - start + 1;
    }

    // Estimate which verse based on scroll position
    final estimatedVerseIndex = (positionInPage * totalVerses).floor();

    // Find the actual verse
    int verseCount = 0;
    for (final surahData in pageData) {
      final surahNum = surahData['surah'] as int;
      final start = surahData['start'] as int;
      final end = surahData['end'] as int;

      for (var v = start; v <= end; v++) {
        if (verseCount == estimatedVerseIndex) {
          final juzNumber = quran.getJuzNumber(surahNum, v);

          final newPosition = ReadingPosition(
            pageNumber: pageNum,
            surahNumber: surahNum,
            verseNumber: v,
            juzNumber: juzNumber,
          );

          if (_currentPosition.verseNumber != newPosition.verseNumber ||
              _currentPosition.surahNumber != newPosition.surahNumber) {
            setState(() {
              _currentPositionNotifier.value = newPosition;
            });
          }
          return;
        }
        verseCount++;
      }
    }
  }

  void _handleLazyLoading() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (currentScroll > maxScroll * 0.8 && _loadedEndPage < _totalPages) {
      setState(() {
        _loadedEndPage = (_loadedEndPage + _loadMoreThreshold).clamp(
          1,
          _totalPages,
        );
      });
    } else if (currentScroll < maxScroll * 0.2 && _loadedStartPage > 1) {
      setState(() {
        _loadedStartPage = (_loadedStartPage - _loadMoreThreshold).clamp(
          1,
          _totalPages,
        );
      });
    }
  }

  void _jumpToPage(int pageNumber) {
    setState(() {
      _loadedStartPage = (pageNumber - 2).clamp(1, _totalPages);
      _loadedEndPage = (pageNumber + 2).clamp(1, _totalPages);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pageKey = _pageKeys[pageNumber];
      if (pageKey?.currentContext != null) {
        Scrollable.ensureVisible(
          pageKey!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        actions: [
          IconButton(
            iconSize: 20,
            onPressed: widget.onThemeToggle,
            icon: switch (widget.themeMode) {
              ThemeMode.system => const Icon(Icons.brightness_auto_outlined),
              ThemeMode.dark => const Icon(Icons.dark_mode),
              ThemeMode.light => const Icon(Icons.light_mode),
            },
          ),
          const SizedBox(width: 5),
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (context) => SettingsBottomSheet(
                fontFamily: context.textTheme.bodyLarge?.fontFamily ?? '',
                onThemeToggle: widget.onThemeToggle,
                onFontFamilyChange: widget.onFontFamilyChange,
              ),
            ),
            icon: const Icon(Icons.settings),
            iconSize: 20,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                PinnedHeaderSliver(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerLow,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getArabicNumber(_currentPosition.surahNumber) +
                              '- ${quran.getSurahNameArabic(_currentPosition.surahNumber)}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                            fontFamily: 'kitab',
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Text(
                          _getArabicNumber(_currentPosition.pageNumber),
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'kitab',
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurface,
                            height: 1,
                          ),
                        ),
                        Text(
                          'جزء ${_getArabicNumber(_currentPosition.juzNumber)}',
                          style: TextStyle(
                            fontFamily: 'kitab',
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: _loadedEndPage - _loadedStartPage + 1,
                  itemBuilder: (context, index) {
                    final pageNumber = _loadedStartPage + index;
                    _pageKeys[pageNumber] ??= GlobalKey();

                    return QuranPageWidget(
                      key: _pageKeys[pageNumber],
                      pageNumber: pageNumber,
                    );
                  },
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomBar(
                key: _bottomBarKey,
                onBookmarks: () => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) =>
                      BookmarksPage(onNavigateToPage: _jumpToPage),
                ),
                onSearch: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (context) =>
                      QuranSearchBottomSheet(onNavigateToPage: _jumpToPage),
                ),
                onNavigate: () => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => QuranNavigationBottomSheet(
                    initialPage: _currentPosition.pageNumber,
                    onNavigate: _jumpToPage,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuranPageWidget extends StatefulWidget {
  const QuranPageWidget({required this.pageNumber, super.key});

  final int pageNumber;

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  late final QuranPage page;
  late final Map<int, Map<int, LongPressGestureRecognizer>> verseRecognizers =
      {};
  ({int surah, int verse})? selectedVerse;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadPageData();
    for (final surah in page.surahs) {
      verseRecognizers[surah.surahNumber] = {
        for (final element in surah.verses)
          element.number: LongPressGestureRecognizer()
            ..onLongPress = () => _handlePress(surah.surahNumber, element),
      };
    }
  }

  void _handlePress(int surahNumber, Verse verse) {
    setState(() {
      selectedVerse = (surah: surahNumber, verse: verse.number);
    });
    _showVerseMenu(surahNumber, verse);
    HapticFeedback.lightImpact();
  }

  void _showVerseMenu(int surah, Verse verse) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => VerseMenuOverlay(
        surah: surah,
        verse: verse,
        onDismiss: () {
          _removeOverlay();
          setState(() {
            selectedVerse = null;
          });
        },
        onBookmarkToggled: () {
          setState(() {});
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _loadPageData() {
    final pageData = quran.getPageData(widget.pageNumber);

    page = QuranPage(
      pageNumber: widget.pageNumber,
      surahs: pageData
          .map(
            (e) => SurahInPage(
              surahNumber: e['surah'] as int,
              verses: _surahVersesInPage(
                surahNumber: e['surah'] as int,
                start: e['start'] as int,
                end: e['end'] as int,
              ),
            ),
          )
          .toList(),
    );
  }

  List<Verse> _surahVersesInPage({
    required int surahNumber,
    required int start,
    required int end,
  }) {
    final verseNumbers = List.generate(end - start + 1, (i) => i + start);
    return verseNumbers
        .map(
          (verseNumber) => (
            number: verseNumber,
            text: quran.getVerse(surahNumber, verseNumber),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final recognizer in verseRecognizers.values.expand((e) => e.values)) {
      recognizer.dispose();
    }
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...page.surahs.map((surah) {
            return RichText(
              textWidthBasis: TextWidthBasis.longestLine,
              textAlign: quran.getVerseCount(surah.surahNumber) <= 20
                  ? TextAlign.center
                  : TextAlign.justify,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: context.textTheme.bodyLarge?.fontFamily,
                  color: context.colorScheme.onSurface,
                ),
                children: surah.verses.map((verse) {
                  final isFirstVerse = verse.number == 1;
                  final isSelected =
                      selectedVerse?.surah == surah.surahNumber &&
                      selectedVerse?.verse == verse.number;
                  return TextSpan(
                    style: TextStyle(
                      fontSize: 24,

                      backgroundColor: isSelected
                          ? Colors.blue.withOpacity(0.2)
                          : null,
                      fontFamily: context.textTheme.bodyLarge?.fontFamily,
                      color: context.colorScheme.onSurface,
                    ),
                    children: [
                      if (isFirstVerse) ...[
                        WidgetSpan(child: _buildSurahHeader(surah.surahNumber)),
                        if (surah.hasBasmala) _buildBasmala(),
                      ],
                      TextSpan(
                        recognizer:
                            verseRecognizers[surah.surahNumber]![verse.number],
                        text: surah.isAlfatihah || verse.number != 1
                            ? verse.text
                            : stripBasmala(verse.text),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: quran.getVerseEndSymbol(verse.number),
                        style: const TextStyle(
                          fontFamily: 'Kitab',
                          fontSize: 26,
                        ),
                      ),
                      const TextSpan(text: ' '),
                    ],
                  );
                }).toList(),
              ),
            );
          }),
          const Divider(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSurahHeader(int surahNumber) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: context.colorScheme.onPrimaryContainer,
                height: 1,
                fontFamily: 'Hafs',
              ),
              children: [
                const TextSpan(
                  text: 'ترتيبها ',
                  style: TextStyle(fontSize: 16),
                ),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: _getArabicNumber(surahNumber),

                  style: const TextStyle(fontSize: 24, height: 1.3),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'سورة ${quran.getSurahNameArabic(surahNumber)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: 'Hafs',
              ),
            ),
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: context.colorScheme.onPrimaryContainer,
                fontFamily: 'Hafs',
                height: 1,
              ),
              children: [
                const TextSpan(text: 'آياتها ', style: TextStyle(fontSize: 16)),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: _getArabicNumber(quran.getVerseCount(surahNumber)),
                  style: const TextStyle(fontSize: 24, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  WidgetSpan _buildBasmala() {
    return const WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: SizedBox(
        height: 60,
        width: double.infinity,
        child: Text(
          quran.basmala,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  String stripBasmala(String text) {
    return text.replaceRange(0, quran.basmala.length + 1, '').trim();
  }
}

String _getArabicNumber(int number) {
  const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number
      .toString()
      .split('')
      .map((digit) => arabicNumerals[int.parse(digit)])
      .join();
}

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;
}
