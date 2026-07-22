import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:huespill/ui/core/theme/app_colors.dart';
import 'package:huespill/ui/core/widgets/tangible_button.dart';
import 'package:huespill/ui/features/game/hue_spill/hue_spill_engine.dart';
import 'package:huespill/ui/features/game/hue_spill/hue_spill_state.dart';
import 'package:huespill/ui/providers.dart';

final hueSpillViewModelProvider =
    StateNotifierProvider.autoDispose<HueSpillViewModel, HueSpillState>(
      (ref) => HueSpillViewModel(),
    );

class HueSpillView extends ConsumerStatefulWidget {
  const HueSpillView({
    super.key,
    required this.levelNumber,
    this.isRandom = false,
  });

  final int levelNumber;
  final bool isRandom;

  @override
  ConsumerState<HueSpillView> createState() => _HueSpillViewState();
}

class _HueSpillViewState extends ConsumerState<HueSpillView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(hueSpillViewModelProvider.notifier)
          .initGame(widget.levelNumber);
    });
  }

  void _showCompletionDialog(bool isVictory) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1.0),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isVictory
                      ? const Color(0xFF10B981)
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.0),
                ),
                child: Icon(
                  isVictory
                      ? Icons.emoji_events_rounded
                      : Icons.water_drop_outlined,
                  color: AppColors.headingDark,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isVictory ? 'LEVEL COMPLETE!' : 'FLOOD FAILED!',
                  style: const TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.headingDark,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isVictory
                      ? 'You flooded the board in ${ref.read(hueSpillViewModelProvider).moves} moves!'
                      : 'Ran out of moves. Try again!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtext,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    TangibleButton(
                      text: isVictory ? 'Next Level' : 'Try Again',
                      height: 50,
                      onPressed: () {
                        Navigator.pop(context);
                        if (isVictory) {
                          if (widget.isRandom) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HueSpillView(
                                  levelNumber: widget.levelNumber,
                                  isRandom: true,
                                ),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HueSpillView(
                                  levelNumber: widget.levelNumber + 1,
                                ),
                              ),
                            );
                          }
                        } else {
                          ref
                              .read(hueSpillViewModelProvider.notifier)
                              .resetLevel();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TangibleButton(
                      text: 'Home',
                      isSecondary: true,
                      height: 50,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 14),
                    TangibleButton(
                      text: 'Buy Me a Coffee ☕',
                      isSecondary: true,
                      height: 50,
                      onPressed: () async {
                        final Uri url = Uri.parse('https://buymeacoffee.com/sidhant947');
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          debugPrint('Could not launch $url');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hueSpillViewModelProvider);
    final notifier = ref.read(hueSpillViewModelProvider.notifier);

    ref.listen<HueSpillState>(hueSpillViewModelProvider, (previous, next) {
      if (next.status != HueSpillStatus.playing &&
          previous?.status == HueSpillStatus.playing) {
        final isVictory = next.status == HueSpillStatus.won;
        HapticFeedback.heavyImpact();

        if (isVictory && !widget.isRandom) {
          Future.microtask(() async {
            final repo = ref.read(progressRepositoryProvider);
            await repo.completeLevel(widget.levelNumber, next.moves);
            await repo.recordLevelResult(
              widget.levelNumber,
              next.moves,
              next.elapsedSeconds,
            );
            // Instantly sync the Home Screen provider so it's fresh when user returns
            ref.read(homeViewModelProvider.notifier).loadProgress();
          });
        }

        if (!context.mounted) return;
        _showCompletionDialog(isVictory);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 18,
                    onTap: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.isRandom
                        ? 'RANDOM PUZZLE'
                        : 'LEVEL ${widget.levelNumber}',
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.headingDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                  _circleButton(
                    icon: Icons.undo_rounded,
                    iconSize: 20,
                    onTap: state.canUndo ? () => notifier.undo() : () {},
                    iconColor: state.canUndo
                        ? AppColors.headingDark
                        : AppColors.subtext,
                  ),
                ],
              ),
            ),

            // Stats Bar
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stat(
                    'MOVES',
                    '${state.moves}/${state.maxMoves}',
                    Icons.trending_up_rounded,
                  ),
                ],
              ),
            ),

            // Game Grid
            Expanded(
              child: state.grid.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white24,
                                width: 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: state.gridSize,
                                    ),
                                itemCount: state.gridSize * state.gridSize,
                                itemBuilder: (context, index) {
                                  final r = index ~/ state.gridSize;
                                  final c = index % state.gridSize;
                                  final colorIndex = state.grid[r][c];
                                  return Transform.scale(
                                    scale: 1.05,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      color: HueSpillEngine.colors[colorIndex],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            // Color Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16.0,
                runSpacing: 16.0,
                children: List.generate(state.numColors, (index) {
                  final isActive =
                      state.grid.isNotEmpty && state.grid[0][0] == index;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      notifier.changeColor(index);
                    },
                    child: AnimatedScale(
                      scale: isActive ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: HueSpillEngine.colors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white24,
                            width: 2.0,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: HueSpillEngine.colors[index]
                                        .withValues(alpha: 0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 20,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.0),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? AppColors.headingDark,
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.headingDark),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.headingDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.subtext,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
