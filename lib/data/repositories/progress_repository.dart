import '/domain/models/user_progress.dart';
import '../services/hive_service.dart';

class ProgressRepository {
  ProgressRepository({required this._hiveService});

  final HiveService _hiveService;
  UserProgress? _cachedProgress;

  Future<UserProgress> getProgress() async {
    if (_cachedProgress != null) return _cachedProgress!;
    _cachedProgress = await _hiveService.getProgress();
    return _cachedProgress!;
  }

  Future<void> saveProgress(UserProgress progress) async {
    _cachedProgress = progress;
    await _hiveService.saveProgress(progress);
  }

  Future<void> completeLevel(int levelNumber, int moves) async {
    final current = await getProgress();
    final isNewCompletion = levelNumber == current.highestLevelCompleted + 1;
    final updated = isNewCompletion
        ? current.incrementLevel().addMoves(moves)
        : current.addMoves(moves);
    await saveProgress(updated);
  }

  /// Records the best moves/time for a completed level.
  Future<void> recordLevelResult(int level, int moves, int seconds) async {
    final current = await getProgress();
    await saveProgress(current.recordLevelResult(level, moves, seconds));
  }

  Future<void> resetProgress() async {
    _cachedProgress = null;
    await _hiveService.clearProgress();
  }
}
