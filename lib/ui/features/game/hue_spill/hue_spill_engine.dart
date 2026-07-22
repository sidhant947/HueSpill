import 'dart:math';
import 'package:flutter/material.dart';

class HueSpillEngine {
  final Random _random = Random();
  
  static const List<Color> colors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFFEC4899), // Pink
    Color(0xFF22C55E), // Green
    Color(0xFFF97316), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFFEAB308), // Yellow
    Color(0xFF8B5CF6), // Purple
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
  ];

  static int gridSizeForLevel(int level) {
    // Exponentially approaches 20x20
    final size = 8 + (level * 0.4).floor();
    return min(size, 20);
  }

  static int numColorsForLevel(int level) {
    // Increases up to 9 colors
    if (level <= 3) return 4;
    if (level <= 8) return 5;
    if (level <= 15) return 6;
    if (level <= 25) return 7;
    if (level <= 40) return 8;
    return 9;
  }

  List<List<int>> generateGrid(int size, [int numColors = 6]) {
    return List.generate(
      size,
      (_) => List.generate(size, (_) => _random.nextInt(numColors)),
    );
  }

  void floodFill(List<List<int>> grid, int r, int c, int targetColor, int replacementColor) {
    if (targetColor == replacementColor) return;
    if (r < 0 || r >= grid.length || c < 0 || c >= grid[0].length) return;
    if (grid[r][c] != targetColor) return;

    grid[r][c] = replacementColor;

    floodFill(grid, r + 1, c, targetColor, replacementColor);
    floodFill(grid, r - 1, c, targetColor, replacementColor);
    floodFill(grid, r, c + 1, targetColor, replacementColor);
    floodFill(grid, r, c - 1, targetColor, replacementColor);
  }

  bool isSolved(List<List<int>> grid) {
    final firstColor = grid[0][0];
    for (var row in grid) {
      for (var cell in row) {
        if (cell != firstColor) return false;
      }
    }
    return true;
  }

  int countFloodArea(List<List<int>> grid) {
    if (grid.isEmpty) return 0;
    final targetColor = grid[0][0];
    int count = 0;
    List<List<bool>> visited = List.generate(grid.length, (_) => List.generate(grid[0].length, (_) => false));
    
    void dfs(int r, int c) {
      if (r < 0 || r >= grid.length || c < 0 || c >= grid[0].length) return;
      if (visited[r][c] || grid[r][c] != targetColor) return;
      visited[r][c] = true;
      count++;
      dfs(r + 1, c);
      dfs(r - 1, c);
      dfs(r, c + 1);
      dfs(r, c - 1);
    }
    
    dfs(0, 0);
    return count;
  }

  int totalCells(List<List<int>> grid) {
    if (grid.isEmpty) return 0;
    return grid.length * grid[0].length;
  }

  int solveGreedy(List<List<int>> initialGrid, int numColors) {
    List<List<int>> grid = initialGrid.map((row) => List<int>.from(row)).toList();
    int moves = 0;
    
    while (!isSolved(grid) && moves < 200) { // Add safety cutoff
      int bestColor = -1;
      int maxAbsorbed = -1;
      final currentColor = grid[0][0];
      final currentArea = countFloodArea(grid);

      for (int c = 0; c < numColors; c++) {
        if (c == currentColor) continue;
        
        List<List<int>> simGrid = grid.map((row) => List<int>.from(row)).toList();
        floodFill(simGrid, 0, 0, currentColor, c);
        int area = countFloodArea(simGrid);
        
        if (area > maxAbsorbed) {
          maxAbsorbed = area;
          bestColor = c;
        }
      }
      
      if (maxAbsorbed <= currentArea || bestColor == -1) {
        // Fallback: just pick a color to avoid infinite loop
        bestColor = (currentColor + 1) % numColors;
      }
      
      floodFill(grid, 0, 0, currentColor, bestColor);
      moves++;
    }
    return moves;
  }
}
