import 'package:flutter/material.dart';

class FloatingBottomBar extends StatefulWidget {
  const FloatingBottomBar({
    // required this.onSettings,
    required this.onSearch,
    required this.onNavigate,
    required this.onBookmarks,

    super.key,
  });
  // final VoidCallback onSettings;
  final VoidCallback onSearch;
  final VoidCallback onNavigate;
  final VoidCallback onBookmarks;

  @override
  State<FloatingBottomBar> createState() => FloatingBottomBarState();
}

class FloatingBottomBarState extends State<FloatingBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, 2)).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void show() {
    if (!_isVisible) {
      _animationController.reverse();
      _isVisible = true;
    }
  }

  void hide() {
    if (_isVisible) {
      _animationController.forward();
      _isVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.15).round()),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconButton(
                icon: Icons.search_rounded,
                onPressed: widget.onSearch,
                tooltip: 'بحث',
                colorScheme: colorScheme,
              ),
              _buildIconButton(
                icon: Icons.menu_book_rounded,
                onPressed: widget.onNavigate,
                tooltip: 'انتقال سريع',
                colorScheme: colorScheme,
                isHighlighted: true,
              ),
              _buildIconButton(
                icon: Icons.bookmark_border_outlined,
                onPressed: widget.onBookmarks,
                tooltip: 'العلامات المرجعية',
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required ColorScheme colorScheme,
    bool isHighlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: isHighlighted
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerLow,
                )
              : null,
          child: Icon(
            icon,
            size: 26,
            color: isHighlighted
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
