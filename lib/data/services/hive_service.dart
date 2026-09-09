import 'dart:ui';
import 'package:hive_flutter/hive_flutter.dart';

import '/domain/models/user_progress.dart';
import 'user_progress_adapter.dart';

class HiveService {
  static const String _progressBoxName = 'huespill';
  static const String _settingsBoxName = 'settings';
  static const String _progressKey = 'progress';
  static const String _colorsKey = 'custom_colors';
  static const String _colorblindKey = 'colorblind_mode';

  late Box<UserProgress> _progressBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserProgressAdapter());
    _progressBox = await Hive.openBox<UserProgress>(_progressBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  Future<UserProgress> getProgress() async {
    return _progressBox.get(_progressKey) ?? const UserProgress();
  }

  Future<void> saveProgress(UserProgress progress) async {
    await _progressBox.put(_progressKey, progress);
  }

  Future<void> clearProgress() async {
    await _progressBox.delete(_progressKey);
  }

  List<Color>? getCustomColors() {
    final raw = _settingsBox.get(_colorsKey);
    if (raw is List) {
      return raw.map((val) => Color(val as int)).toList();
    }
    return null;
  }

  Future<void> saveCustomColors(List<Color> colors) async {
    final values = colors.map((c) => c.toARGB32()).toList();
    await _settingsBox.put(_colorsKey, values);
  }

  Future<void> resetCustomColors() async {
    await _settingsBox.delete(_colorsKey);
  }

  bool isColorblindModeEnabled() {
    return _settingsBox.get(_colorblindKey, defaultValue: false) as bool;
  }

  Future<void> setColorblindMode(bool enabled) async {
    await _settingsBox.put(_colorblindKey, enabled);
  }
}
