import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huespill/data/repositories/progress_repository.dart';
import 'package:huespill/data/services/hive_service.dart';
import 'package:huespill/ui/features/game/hue_spill/hue_spill_engine.dart';
import 'package:huespill/ui/features/home/view_models/home_view_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ProgressRepository(hiveService: hiveService);
});

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeViewModelState>((ref) {
      final progressRepository = ref.watch(progressRepositoryProvider);
      return HomeViewModel(progressRepository: progressRepository);
    });

class GameColorsNotifier extends StateNotifier<List<Color>> {
  final HiveService _hiveService;

  GameColorsNotifier(this._hiveService)
      : super(_hiveService.getCustomColors() ?? HueSpillEngine.defaultColors) {
    HueSpillEngine.colors = state;
  }

  Future<void> updateColor(int index, Color color) async {
    if (index < 0 || index >= state.length) return;
    final updated = List<Color>.from(state);
    updated[index] = color;
    state = updated;
    HueSpillEngine.colors = updated;
    await _hiveService.saveCustomColors(updated);
  }

  Future<void> resetColors() async {
    state = HueSpillEngine.defaultColors;
    HueSpillEngine.colors = HueSpillEngine.defaultColors;
    await _hiveService.resetCustomColors();
  }
}

final gameColorsProvider =
    StateNotifierProvider<GameColorsNotifier, List<Color>>((ref) {
      final hiveService = ref.watch(hiveServiceProvider);
      return GameColorsNotifier(hiveService);
    });

class ColorblindModeNotifier extends StateNotifier<bool> {
  final HiveService _hiveService;

  ColorblindModeNotifier(this._hiveService)
      : super(_hiveService.isColorblindModeEnabled());

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _hiveService.setColorblindMode(enabled);
  }

  Future<void> toggle() async {
    state = !state;
    await _hiveService.setColorblindMode(state);
  }
}

final colorblindModeProvider =
    StateNotifierProvider<ColorblindModeNotifier, bool>((ref) {
      final hiveService = ref.watch(hiveServiceProvider);
      return ColorblindModeNotifier(hiveService);
    });



