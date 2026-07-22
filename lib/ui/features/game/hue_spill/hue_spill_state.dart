import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hue_spill_engine.dart';

enum HueSpillStatus { playing, won, lost }

@immutable
class HueSpillState {
  const HueSpillState({
    this.grid = const [],
    this.moves = 0,
    this.maxMoves = 22,
    this.gridSize = 8,
    this.numColors = 4,
    this.status = HueSpillStatus.playing,
    this.level = 1,
    this.floodArea = 0,
    this.totalCells = 0,
    this.elapsedSeconds = 0,
  });

  final List<List<int>> grid;
  final int moves;
  final int maxMoves;
  final int gridSize;
  final int numColors;
  final HueSpillStatus status;
  final int level;
  final int floodArea;
  final int totalCells;
  final int elapsedSeconds;

  HueSpillState copyWith({
    List<List<int>>? grid,
    int? moves,
    int? maxMoves,
    int? gridSize,
    int? numColors,
    HueSpillStatus? status,
    int? level,
    int? floodArea,
    int? totalCells,
    int? elapsedSeconds,
  }) {
    return HueSpillState(
      grid: grid ?? this.grid,
      moves: moves ?? this.moves,
      maxMoves: maxMoves ?? this.maxMoves,
      gridSize: gridSize ?? this.gridSize,
      numColors: numColors ?? this.numColors,
      status: status ?? this.status,
      level: level ?? this.level,
      floodArea: floodArea ?? this.floodArea,
      totalCells: totalCells ?? this.totalCells,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  double get progress => totalCells > 0 ? floodArea / totalCells : 0.0;
  bool get canUndo => moves > 0;
}

class HueSpillViewModel extends StateNotifier<HueSpillState> {
  HueSpillViewModel() : super(const HueSpillState());

  final _engine = HueSpillEngine();

  final List<HueSpillState> _history = [];

  void initGame(int level) {
    _history.clear();
    final gridSize = HueSpillEngine.gridSizeForLevel(level);
    final numColors = HueSpillEngine.numColorsForLevel(level);

    final grid = _engine.generateGrid(gridSize, numColors);
    
    // Compute guaranteed minimum moves using greedy solver
    final greedyMoves = _engine.solveGreedy(grid, numColors);
    
    // Exponentially decreasing padding: starts at +6, decays towards +1
    final padding = math.max(1, (6 - level * 0.15).floor());
    
    final maxMoves = greedyMoves + padding;

    state = HueSpillState(
      grid: grid,
      moves: 0,
      maxMoves: maxMoves,
      gridSize: gridSize,
      numColors: numColors,
      status: HueSpillStatus.playing,
      level: level,
      floodArea: _engine.countFloodArea(grid),
      totalCells: _engine.totalCells(grid),
      elapsedSeconds: 0,
    );
  }

  void changeColor(int colorIndex) {
    if (state.status != HueSpillStatus.playing) return;
    if (state.grid.isEmpty) return;
    if (colorIndex == state.grid[0][0]) return;

    final newGrid = state.grid.map((row) => List<int>.from(row)).toList();
    _engine.floodFill(newGrid, 0, 0, state.grid[0][0], colorIndex);

    final newMoves = state.moves + 1;
    final floodArea = _engine.countFloodArea(newGrid);
    HueSpillStatus newStatus = state.status;

    if (_engine.isSolved(newGrid)) {
      newStatus = HueSpillStatus.won;
    } else if (newMoves >= state.maxMoves) {
      newStatus = HueSpillStatus.lost;
    }

    _history.add(state);

    state = state.copyWith(
      grid: newGrid,
      moves: newMoves,
      status: newStatus,
      floodArea: floodArea,
    );
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
    }
  }

  void resetLevel() {
    initGame(state.level);
  }
}
