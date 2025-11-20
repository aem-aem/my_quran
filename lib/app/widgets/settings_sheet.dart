import 'package:flutter/material.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({
    required this.onThemeToggle,
    required this.onFontFamilyChange,
    required this.fontFamily,
    super.key,
  });
  final VoidCallback onThemeToggle;
  final ValueChanged<String> onFontFamilyChange;
  final String fontFamily;
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      height: 200,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('الوضع الليلي'),
            value: isDarkMode,
            onChanged: (_) => onThemeToggle(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الخط'),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(4),
                  onPressed: (index) =>
                      onFontFamilyChange(index == 0 ? 'kitab' : 'Hafs'),
                  isSelected: [fontFamily == 'kitab', fontFamily == 'Hafs'],
                  children: [
                    _buildToggleButton('الخط الأول'),
                    _buildToggleButton('الخط الثاني'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text),
    );
  }
}
