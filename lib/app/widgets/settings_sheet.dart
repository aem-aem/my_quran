import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({
    required this.onThemeToggle,
    required this.onFontFamilyChange,
    required this.fontFamily,
    super.key,
  });
  final VoidCallback onThemeToggle;
  final ValueChanged<FontFamily> onFontFamilyChange;
  final FontFamily fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('نوع الخط'),
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(4),
                    onPressed: (index) =>
                        onFontFamilyChange(FontFamily.values.elementAt(index)),
                    isSelected: FontFamily.values
                        .map((f) => f == fontFamily)
                        .toList(),
                    children: FontFamily.values
                        .map((f) => _buildToggleButton(f.arabicName))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(text),
    );
  }
}
