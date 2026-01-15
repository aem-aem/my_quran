import 'package:flutter/material.dart';
import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/utils.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    required this.fontController,
    required this.settingsController,
    super.key,
  });
  final SettingsController settingsController;
  final FontSizeController fontController;

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(fontWeight: FontWeight.w600);
    final colorScheme = context.colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([fontController, settingsController]),
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('حجم الخط', style: titleStyle),
                        const Spacer(),
                        IconButton.filled(
                          onPressed: fontController.decreaseFontSize,
                          icon: const Icon(Icons.remove),
                        ),
                        Expanded(
                          child: Text(
                            fontController.fontSize.round().toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              fontFamily:
                                  FontFamily.arabicNumbersFontFamily.name,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: fontController.increaseFontSize,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نوع الخط', style: titleStyle),
                      SegmentedButton<FontFamily>(
                        segments: const [
                          ButtonSegment(
                            value: FontFamily.hafs,
                            label: Text('حفص'),
                          ),
                          ButtonSegment(
                            value: FontFamily.rustam,
                            label: Text('المدينة'),
                          ),
                        ],
                        style: ButtonStyle(
                          textStyle: WidgetStatePropertyAll(
                            TextStyle(fontFamily: FontFamily.hafs.name),
                          ),
                          foregroundColor: WidgetStateColor.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return colorScheme.onPrimary;
                            }
                            return colorScheme.onSurfaceVariant;
                          }),
                          backgroundColor: WidgetStateColor.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return colorScheme.primary;
                            }
                            return colorScheme.surfaceContainer;
                          }),
                          side: WidgetStatePropertyAll(
                            BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        selected: {settingsController.fontFamily},
                        onSelectionChanged: (newSelection) {
                          settingsController.fontFamily = newSelection.first;
                        },
                      ),
                    ],
                  ),
                  if (settingsController.fontFamily == FontFamily.hafs) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سماكة الخط', style: titleStyle),
                        SegmentedButton<FontWeight>(
                          segments: const [
                            ButtonSegment(
                              value: FontWeight.w500,
                              label: Text('عادي'),
                            ),
                            ButtonSegment(
                              value: FontWeight.w600,
                              label: Text('عريض'),
                            ),
                          ],
                          style: ButtonStyle(
                            textStyle: WidgetStatePropertyAll(
                              TextStyle(fontFamily: FontFamily.hafs.name),
                            ),
                            foregroundColor: WidgetStateColor.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return colorScheme.onPrimary;
                              }
                              return colorScheme.onSurfaceVariant;
                            }),
                            backgroundColor: WidgetStateColor.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return colorScheme.primary;
                              }
                              return colorScheme.surfaceContainer;
                            }),
                            side: WidgetStatePropertyAll(
                              BorderSide(color: colorScheme.primary),
                            ),
                          ),
                          selected: {settingsController.fontWeight},
                          onSelectionChanged: (newSelection) {
                            settingsController.fontWeight = newSelection.first;
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text(
            'استخدام اللون الأسود لخلفية الوضع الداكن',
            style: titleStyle,
          ),
          subtitle: const Text(
            'يساعد على تقليل استهلاك البطارية فقط إذا كانت شاشة الهاتف من نوع AMOLED',
          ),
          value: settingsController.useTrueBlackBgColor,
          onChanged: (value) => settingsController.useTrueBlackBgColor = value,
        ),
      ],
    );
  }
}
