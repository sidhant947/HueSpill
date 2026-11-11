import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:huespill/ui/core/theme/app_colors.dart';
import 'package:huespill/ui/core/widgets/tangible_button.dart';
import 'package:huespill/ui/features/game/hue_spill/hue_spill_engine.dart';
import 'package:huespill/ui/features/game/hue_spill/hue_spill_state.dart';
import 'package:url_launcher/url_launcher.dart';
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
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    Future.microtask(() {
      ref
          .read(hueSpillViewModelProvider.notifier)
          .initGame(widget.levelNumber);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hueSpillViewModelProvider);
    final notifier = ref.read(hueSpillViewModelProvider.notifier);
    final colors = ref.watch(gameColorsProvider);
    final isColorblind = ref.watch(colorblindModeProvider);

    ref.listen<HueSpillState>(hueSpillViewModelProvider, (previous, next) {
      if (next.status != HueSpillStatus.playing &&
          previous?.status == HueSpillStatus.playing) {
        final isVictory = next.status == HueSpillStatus.won;
        HapticFeedback.heavyImpact();

        if (isVictory) {
          _confettiController.play();
          if (!widget.isRandom) {
            Future.microtask(() async {
              final repo = ref.read(progressRepositoryProvider);
              await repo.completeLevel(widget.levelNumber, next.moves);
              await repo.recordLevelResult(
                widget.levelNumber,
                next.moves,
                next.elapsedSeconds,
              );
              ref.read(homeViewModelProvider.notifier).loadProgress();
            });
          }
        }
      } else if (next.status == HueSpillStatus.playing &&
          previous?.status != HueSpillStatus.playing) {
        _confettiController.stop();
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

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stat(
                    'MOVES',
                    '${state.moves}/${state.maxMoves}',
                    Icons.trending_up_rounded,
                  ),
                  const SizedBox(width: 56),
                  _stat(
                    'TIME',
                    state.formattedTime,
                    Icons.timer_outlined,
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
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
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
                                      return AnimatedGridTile(
                                        r: r,
                                        c: c,
                                        color: colors[colorIndex],
                                        symbol: isColorblind
                                            ? HueSpillEngine.colorblindIcons[colorIndex]
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: ConfettiWidget(
                                  confettiController: _confettiController,
                                  blastDirectionality: BlastDirectionality.explosive,
                                  shouldLoop: true,
                                  colors: colors,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            if (state.status == HueSpillStatus.playing)
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
                            color: colors[index],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white24,
                              width: 2.0,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: colors[index]
                                          .withValues(alpha: 0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isColorblind
                              ? Icon(
                                  HueSpillEngine.colorblindIcons[index],
                                  size: 26,
                                  color: colors[index].computeLuminance() > 0.45
                                      ? Colors.black87
                                      : Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.status == HueSpillStatus.won
                          ? 'CONGRATULATIONS!'
                          : 'FLOOD FAILED!',
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.headingDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TangibleButton(
                      text: state.status == HueSpillStatus.won
                          ? 'Next Level'
                          : 'Try Again',
                      height: 40,
                      fontSize: 16,
                      onPressed: () {
                        if (state.status == HueSpillStatus.won) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HueSpillView(
                                levelNumber: widget.isRandom
                                    ? widget.levelNumber
                                    : widget.levelNumber + 1,
                                isRandom: widget.isRandom,
                              ),
                            ),
                          );
                        } else {
                          notifier.resetLevel();
                        }
                      },
                    ),
                    if (state.status == HueSpillStatus.won) ...[
                      const SizedBox(height: 8),
                      TangibleButton(
                        text: 'Home',
                        isSecondary: true,
                        height: 40,
                        fontSize: 16,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 8),
                      TangibleButton(
                        text: 'Buy Me a Coffee ☕',
                        isSecondary: true,
                        height: 40,
                        fontSize: 16,
                        onPressed: () => launchUrl(
                          Uri.parse('https://ko-fi.com/sidhant947'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
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

class AnimatedGridTile extends StatefulWidget {
  final int r;
  final int c;
  final Color color;
  final IconData? symbol;

  const AnimatedGridTile({
    super.key,
    required this.r,
    required this.c,
    required this.color,
    this.symbol,
  });

  @override
  State<AnimatedGridTile> createState() => _AnimatedGridTileState();
}

class _AnimatedGridTileState extends State<AnimatedGridTile> {
  late Color _currentColor;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.color;
  }

  @override
  void didUpdateWidget(covariant AnimatedGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      final delay = Duration(milliseconds: (widget.r + widget.c) * 35);
      Future.delayed(delay, () {
        if (mounted) {
          setState(() {
            _currentColor = widget.color;
            _scale = 1.15;
          });
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              setState(() {
                _scale = 1.0;
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale * 1.05,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        color: _currentColor,
        child: widget.symbol != null
            ? Center(
                child: FractionallySizedBox(
                  widthFactor: 0.65,
                  heightFactor: 0.65,
                  child: FittedBox(
                    child: Icon(
                      widget.symbol,
                      color: _currentColor.computeLuminance() > 0.45
                          ? Colors.black87
                          : Colors.white,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
