import 'dart:math' as math;

import 'package:flutter/material.dart';

@immutable
class UserProgress {
  const UserProgress({
    this.currentLevel = 1,
    this.highestLevelCompleted = 0,
    this.totalMoves = 0,
    this.bestMoves = const {},
    this.bestTimeSeconds = const {},
  });

  final int currentLevel;
  final int highestLevelCompleted;
  final int totalMoves;

  /// Best (fewest) moves recorded per level number.
  final Map<int, int> bestMoves;

  /// Best (fastest) completion time in seconds per level number.
  final Map<int, int> bestTimeSeconds;

  UserProgress copyWith({
    int? currentLevel,
    int? highestLevelCompleted,
    int? totalMoves,
    Map<int, int>? bestMoves,
    Map<int, int>? bestTimeSeconds,
  }) {
    return UserProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      highestLevelCompleted:
          highestLevelCompleted ?? this.highestLevelCompleted,
      totalMoves: totalMoves ?? this.totalMoves,
      bestMoves: bestMoves ?? this.bestMoves,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
    );
  }

  UserProgress incrementLevel() {
    return copyWith(
      currentLevel: currentLevel + 1,
      highestLevelCompleted: math.max(highestLevelCompleted, currentLevel),
    );
  }

  UserProgress addMoves(int moves) {
    return copyWith(totalMoves: totalMoves + moves);
  }

  /// Records a per-level result, keeping the best (minimum) moves and time.
  UserProgress recordLevelResult(int level, int moves, int seconds) {
    final newBestMoves = Map<int, int>.from(bestMoves);
    final newBestTime = Map<int, int>.from(bestTimeSeconds);

    final priorMoves = newBestMoves[level];
    if (priorMoves == null || moves < priorMoves) {
      newBestMoves[level] = moves;
    }
    final priorTime = newBestTime[level];
    if (priorTime == null || seconds < priorTime) {
      newBestTime[level] = seconds;
    }

    return copyWith(bestMoves: newBestMoves, bestTimeSeconds: newBestTime);
  }
}
