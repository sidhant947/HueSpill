import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:huespill/ui/core/theme/app_colors.dart';
import 'package:huespill/ui/core/widgets/tangible_button.dart';
import 'package:huespill/ui/features/game/hue_spill/hue_spill_engine.dart';
import 'package:huespill/ui/providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  static String _toHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  void _showColorEditDialog(
    BuildContext context,
    WidgetRef ref,
    int index,
    Color currentColor,
  ) {
    final controller = TextEditingController(text: _toHex(currentColor));
    Color previewColor = currentColor;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          void onTextChanged(String text) {
            final clean = text.replaceAll('#', '').trim();
            if (clean.length == 6 || clean.length == 8) {
              final val = int.tryParse(clean, radix: 16);
              if (val != null) {
                final parsed = clean.length == 6
                    ? Color(int.parse('FF$clean', radix: 16))
                    : Color(val);
                setState(() {
                  previewColor = parsed;
                  errorText = null;
                });
                return;
              }
            }
            setState(() {
              errorText = 'Enter 6 hex digits (e.g. EF4444)';
            });
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1.0),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'COLOR ${index + 1}',
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.headingDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: previewColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 2.0),
                    ),
                    child: ref.read(colorblindModeProvider)
                        ? Icon(
                            HueSpillEngine.colorblindIcons[index],
                            size: 28,
                            color: previewColor.computeLuminance() > 0.45
                                ? Colors.black87
                                : Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 8,
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 20,
                      color: AppColors.headingDark,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      prefixText: '# ',
                      prefixStyle: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 20,
                        color: AppColors.subtext,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surface,
                      errorText: errorText,
                      errorStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                    ),
                    onChanged: onTextChanged,
                  ),
                  const SizedBox(height: 20),
                  TangibleButton(
                    text: 'Save Color',
                    onPressed: errorText == null
                        ? () {
                            ref
                                .read(gameColorsProvider.notifier)
                                .updateColor(index, previewColor);
                            Navigator.pop(dialogContext);
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: 'BebasNeue',
                        color: AppColors.subtext,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(gameColorsProvider);
    final isColorblind = ref.watch(colorblindModeProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white24,
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.headingDark,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'SETTINGS',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.headingDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                children: [
                  const Text(
                    'ACCESSIBILITY',
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.headingDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Displays shape symbols on tiles to assist colorblind players.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.subtext,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TangibleButton(
                    text: isColorblind
                        ? 'Colorblind Mode: ON'
                        : 'Colorblind Mode: OFF',
                    isSecondary: !isColorblind,
                    onPressed: () =>
                        ref.read(colorblindModeProvider.notifier).toggle(),
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 20),
                  const Text(
                    'CUSTOMIZE PALETTE',
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.headingDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap any color slot to edit its hex code.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.subtext,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: colors.length,
                    itemBuilder: (context, index) {
                      final color = colors[index];
                      final hex = _toHex(color);
                      return GestureDetector(
                        onTap: () => _showColorEditDialog(
                          context,
                          ref,
                          index,
                          color,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: isColorblind
                                    ? Icon(
                                        HueSpillEngine.colorblindIcons[index],
                                        size: 18,
                                        color: color.computeLuminance() > 0.45
                                            ? Colors.black87
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '#$hex',
                                  style: const TextStyle(
                                    fontFamily: 'BebasNeue',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.headingDark,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TangibleButton(
                    text: 'Reset Palette',
                    isSecondary: true,
                    onPressed: () =>
                        ref.read(gameColorsProvider.notifier).resetColors(),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 24),
                  TangibleButton(
                    text: 'Reset Progress',
                    isSecondary: true,
                    onPressed: () => _confirmReset(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1.0),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RESET PROGRESS?',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.headingDark,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This clears all level progress and best scores. This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtext,
                ),
              ),
              const SizedBox(height: 24),
              TangibleButton(
                text: 'Reset Everything',
                onPressed: () async {
                  await ref.read(homeViewModelProvider.notifier).resetProgress();
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    color: AppColors.subtext,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
