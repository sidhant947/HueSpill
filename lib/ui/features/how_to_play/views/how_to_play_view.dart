import 'package:flutter/material.dart';
import 'package:huespill/ui/core/theme/app_colors.dart';
import 'package:huespill/ui/core/widgets/tangible_button.dart';

class HowToPlayView extends StatelessWidget {
  const HowToPlayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        'HOW TO PLAY',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 26,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 28, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _step(
                      context,
                      1,
                      'The Goal',
                      'Flood the entire board with a single color. Start from the top-left corner and expand your flood area.',
                      Icons.water_drop_rounded,
                      AppColors.surface,
                    ),
                    const SizedBox(height: 20),
                    _step(
                      context,
                      2,
                      'Pick a Color',
                      'Tap one of the color buttons at the bottom to change your flood color. Only colors currently on the board are available.',
                      Icons.palette_rounded,
                      AppColors.surface,
                    ),
                    const SizedBox(height: 20),
                    _step(
                      context,
                      3,
                      'Flood Fill',
                      'When you pick a color, your flood area expands to include all adjacent cells of that color. Plan your moves carefully!',
                      Icons.touch_app_rounded,
                      AppColors.surface,
                    ),
                    const SizedBox(height: 20),
                    _step(
                      context,
                      4,
                      'Beat the Clock',
                      'You have a limited number of moves to flood the board. Use fewer moves to beat the level! As levels increase, the grid gets bigger and moves get tighter.',
                      Icons.timer_outlined,
                      AppColors.surface,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Got It button at the bottom
            Padding(
              padding: const EdgeInsets.all(24),
              child: TangibleButton(
                text: 'Got It!',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(BuildContext context, int num, String title, String desc, IconData icon, Color iconBg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white24,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white24,
                width: 1.0,
              ),
            ),
            child: Center(child: Icon(icon, color: AppColors.headingDark, size: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RULE $num',
                  style: const TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.subtext,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.headingDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.subtext,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
