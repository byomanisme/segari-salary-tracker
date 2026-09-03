import 'dart:math';
import 'package:flutter/material.dart';

class BlockShape {
  final String id;
  final List<List<int>> matrix;
  final Color color;
  final String emoji;
  final IconData icon;
  final String label;

  const BlockShape({
    required this.id,
    required this.matrix,
    required this.color,
    required this.emoji,
    required this.icon,
    required this.label,
  });

  int get rows => matrix.length;
  int get cols => matrix[0].length;
  int get blockCount {
    int count = 0;
    for (final row in matrix) {
      for (final cell in row) {
        if (cell == 1) count++;
      }
    }
    return count;
  }

  // Pre-defined vibrant Segari color palette
  static const Color emerald = Color(0xFF10B981); // Brokoli & Selada Segari 🥦
  static const Color orange = Color(0xFFF97316);  // Wortel Brastagi 🥕
  static const Color rose = Color(0xFFF43F5E);    // Tomat Merah & Stroberi 🍅
  static const Color amber = Color(0xFFF59E0B);   // Jagung Manis & Pisang 🌽
  static const Color purple = Color(0xFF8B5CF6);  // Terong Ungu & Anggur 🍆
  static const Color cyan = Color(0xFF06B6D4);    // Ikan Salmon & Udang 🐟
  static const Color blue = Color(0xFF3B82F6);    // Daging Sapi Segari 🥩

  static String getEmojiForColor(Color color) {
    if (color == emerald) return '🥦';
    if (color == orange) return '🥕';
    if (color == rose) return '🍅';
    if (color == amber) return '🌽';
    if (color == purple) return '🍆';
    if (color == cyan) return '🐟';
    if (color == blue) return '🥩';
    return '🥬';
  }

  static IconData getIconForColor(Color color) {
    if (color == emerald) return Icons.eco_rounded;
    if (color == orange) return Icons.agriculture_rounded;
    if (color == rose) return Icons.favorite_rounded;
    if (color == amber) return Icons.wb_sunny_rounded;
    if (color == purple) return Icons.bubble_chart_rounded;
    if (color == cyan) return Icons.set_meal_rounded;
    return Icons.restaurant_rounded;
  }

  static String getLabelForColor(Color color) {
    if (color == emerald) return 'Brokoli Hijau Segari 🥦';
    if (color == orange) return 'Wortel Brastagi 🥕';
    if (color == rose) return 'Tomat Merah Lembang 🍅';
    if (color == amber) return 'Jagung Manis Segari 🌽';
    if (color == purple) return 'Terong Ungu Segari 🍆';
    if (color == cyan) return 'Ikan Salmon Segar 🐟';
    if (color == blue) return 'Daging Sapi Segari 🥩';
    return 'Sayuran Segari 🥬';
  }

  static List<BlockShape> getAllShapes() {
    return [
      // 1x1 Single
      const BlockShape(
        id: 'dot_1',
        matrix: [[1]],
        color: amber,
        emoji: '🌽',
        icon: Icons.wb_sunny_rounded,
        label: 'Jagung Manis',
      ),

      // 2x1 and 1x2 Domino
      const BlockShape(
        id: 'h_line_2',
        matrix: [[1, 1]],
        color: cyan,
        emoji: '🐟',
        icon: Icons.set_meal_rounded,
        label: 'Ikan Salmon',
      ),
      const BlockShape(
        id: 'v_line_2',
        matrix: [[1], [1]],
        color: cyan,
        emoji: '🐟',
        icon: Icons.set_meal_rounded,
        label: 'Ikan Salmon',
      ),

      // 3x1 and 1x3 Line
      const BlockShape(
        id: 'h_line_3',
        matrix: [[1, 1, 1]],
        color: emerald,
        emoji: '🥦',
        icon: Icons.eco_rounded,
        label: 'Brokoli Segari',
      ),
      const BlockShape(
        id: 'v_line_3',
        matrix: [[1], [1], [1]],
        color: emerald,
        emoji: '🥦',
        icon: Icons.eco_rounded,
        label: 'Brokoli Segari',
      ),

      // 4x1 and 1x4 Line
      const BlockShape(
        id: 'h_line_4',
        matrix: [[1, 1, 1, 1]],
        color: blue,
        emoji: '🥩',
        icon: Icons.restaurant_rounded,
        label: 'Daging Sapi',
      ),
      const BlockShape(
        id: 'v_line_4',
        matrix: [[1], [1], [1], [1]],
        color: blue,
        emoji: '🥩',
        icon: Icons.restaurant_rounded,
        label: 'Daging Sapi',
      ),

      // 5x1 and 1x5 Line
      const BlockShape(
        id: 'h_line_5',
        matrix: [[1, 1, 1, 1, 1]],
        color: purple,
        emoji: '🍆',
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),
      const BlockShape(
        id: 'v_line_5',
        matrix: [[1], [1], [1], [1], [1]],
        color: purple,
        emoji: '🍆',
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),

      // 2x2 Square
      const BlockShape(
        id: 'square_2',
        matrix: [
          [1, 1],
          [1, 1],
        ],
        color: orange,
        emoji: '🥕',
        icon: Icons.agriculture_rounded,
        label: 'Wortel Brastagi',
      ),

      // 3x3 Square
      const BlockShape(
        id: 'square_3',
        matrix: [
          [1, 1, 1],
          [1, 1, 1],
          [1, 1, 1],
        ],
        color: rose,
        emoji: '🍅',
        icon: Icons.favorite_rounded,
        label: 'Tomat Merah',
      ),

      // L Shapes (2x2)
      const BlockShape(
        id: 'l_mini_1',
        matrix: [
          [1, 0],
          [1, 1],
        ],
        color: emerald,
        emoji: '🥦',
        icon: Icons.eco_rounded,
        label: 'Brokoli Segari',
      ),
      const BlockShape(
        id: 'l_mini_2',
        matrix: [
          [0, 1],
          [1, 1],
        ],
        color: emerald,
        emoji: '🥦',
        icon: Icons.eco_rounded,
        label: 'Brokoli Segari',
      ),
      const BlockShape(
        id: 'l_mini_3',
        matrix: [
          [1, 1],
          [1, 0],
        ],
        color: emerald,
        emoji: '🥦',
        icon: Icons.eco_rounded,
        label: 'Brokoli Segari',
      ),
      const BlockShape(
        id: 'l_mini_4',
        matrix: [
          [1, 1],
          [0, 1],
        ],
        color: emerald,
        emoji: '🥦',
        icon: Icons.eco_rounded,
        label: 'Brokoli Segari',
      ),

      // L Shapes (3x3 big)
      const BlockShape(
        id: 'l_big_1',
        matrix: [
          [1, 0, 0],
          [1, 0, 0],
          [1, 1, 1],
        ],
        color: orange,
        emoji: '🥕',
        icon: Icons.agriculture_rounded,
        label: 'Wortel Brastagi',
      ),
      const BlockShape(
        id: 'l_big_2',
        matrix: [
          [0, 0, 1],
          [0, 0, 1],
          [1, 1, 1],
        ],
        color: orange,
        emoji: '🥕',
        icon: Icons.agriculture_rounded,
        label: 'Wortel Brastagi',
      ),
      const BlockShape(
        id: 'l_big_3',
        matrix: [
          [1, 1, 1],
          [1, 0, 0],
          [1, 0, 0],
        ],
        color: orange,
        emoji: '🥕',
        icon: Icons.agriculture_rounded,
        label: 'Wortel Brastagi',
      ),
      const BlockShape(
        id: 'l_big_4',
        matrix: [
          [1, 1, 1],
          [0, 0, 1],
          [0, 0, 1],
        ],
        color: orange,
        emoji: '🥕',
        icon: Icons.agriculture_rounded,
        label: 'Wortel Brastagi',
      ),

      // T Shapes (3x2)
      const BlockShape(
        id: 't_1',
        matrix: [
          [1, 1, 1],
          [0, 1, 0],
        ],
        color: purple,
        emoji: '🍆',
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),
      const BlockShape(
        id: 't_2',
        matrix: [
          [0, 1, 0],
          [1, 1, 1],
        ],
        color: purple,
        emoji: '🍆',
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),
      const BlockShape(
        id: 't_3',
        matrix: [
          [1, 0],
          [1, 1],
          [1, 0],
        ],
        color: purple,
        emoji: '🍆',
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),
      const BlockShape(
        id: 't_4',
        matrix: [
          [0, 1],
          [1, 1],
          [0, 1],
        ],
        color: purple,
        emoji: '🍆',
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),

      // Diagonal 2x2 (2 dots)
      const BlockShape(
        id: 'diag_2_a',
        matrix: [
          [1, 0],
          [0, 1],
        ],
        color: rose,
        emoji: '🍅',
        icon: Icons.favorite_rounded,
        label: 'Tomat Merah',
      ),
      const BlockShape(
        id: 'diag_2_b',
        matrix: [
          [0, 1],
          [1, 0],
        ],
        color: rose,
        emoji: '🍅',
        icon: Icons.favorite_rounded,
        label: 'Tomat Merah',
      ),

      // Plus / Cross shape
      const BlockShape(
        id: 'cross_5',
        matrix: [
          [0, 1, 0],
          [1, 1, 1],
          [0, 1, 0],
        ],
        color: cyan,
        emoji: '🐟',
        icon: Icons.set_meal_rounded,
        label: 'Ikan Salmon',
      ),
    ];
  }

  bool canFitInBoard(List<List<Color?>> board) {
    final bSize = board.length;
    if (rows > bSize || cols > bSize) return false;
    for (int r = 0; r <= bSize - rows; r++) {
      for (int c = 0; c <= bSize - cols; c++) {
        bool fits = true;
        for (int pr = 0; pr < rows; pr++) {
          for (int pc = 0; pc < cols; pc++) {
            if (matrix[pr][pc] == 1 && board[r + pr][c + pc] != null) {
              fits = false;
              break;
            }
          }
          if (!fits) break;
        }
        if (fits) return true;
      }
    }
    return false;
  }

  bool get isSmall => blockCount <= 4 && rows <= 2 && cols <= 2;
  bool get isLarge => blockCount >= 5 || rows >= 3 && cols >= 3 || rows >= 4 || cols >= 4;

  static List<BlockShape> getRandomSet(int count) {
    final all = getAllShapes();
    final random = Random();
    final set = <BlockShape>[];
    for (int i = 0; i < count; i++) {
      set.add(all[random.nextInt(all.length)]);
    }
    return set;
  }

  /// Official Block Blast algorithm: Anti-Deadlock Smart Spawner
  /// Guarantees at least 1 fitting piece and maintains balanced size distribution.
  static List<BlockShape> getSmartSet(List<List<Color?>> board) {
    final all = getAllShapes();
    final random = Random();
    final bSize = board.length;

    // 1. Calculate board density
    int filledCells = 0;
    for (int r = 0; r < bSize; r++) {
      for (int c = 0; c < bSize; c++) {
        if (board[r][c] != null) filledCells++;
      }
    }
    final density = filledCells / (bSize * bSize);

    // 2. Identify all shapes that can currently fit
    final fittingShapes = all.where((s) => s.canFitInBoard(board)).toList();
    final fittingSmall = fittingShapes.where((s) => s.isSmall).toList();

    final result = <BlockShape>[];

    // Guarantee Piece #1: ALWAYS a piece that fits (anti-deadlock)
    if (fittingShapes.isNotEmpty) {
      if (density > 0.60 && fittingSmall.isNotEmpty) {
        // High density: rescue player with small fitting piece
        result.add(fittingSmall[random.nextInt(fittingSmall.length)]);
      } else {
        result.add(fittingShapes[random.nextInt(fittingShapes.length)]);
      }
    } else {
      // Board completely saturated
      result.add(all[random.nextInt(all.length)]);
    }

    // Piece #2: Balanced piece
    if (density > 0.65 && fittingShapes.length > 1) {
      // Board is very full: make 2nd piece also fitting
      final remainingFits = fittingShapes.where((s) => s.id != result[0].id).toList();
      if (remainingFits.isNotEmpty) {
        result.add(remainingFits[random.nextInt(remainingFits.length)]);
      } else {
        result.add(fittingShapes[random.nextInt(fittingShapes.length)]);
      }
    } else {
      // Non-large piece preferred if piece #1 was large
      final pool = result[0].isLarge ? all.where((s) => !s.isLarge).toList() : all;
      result.add(pool[random.nextInt(pool.length)]);
    }

    // Piece #3: Complementary piece (never 3 large pieces in one round)
    final largeCount = result.where((s) => s.isLarge).length;
    final finalPool = (largeCount >= 1)
        ? all.where((s) => !s.isLarge).toList()
        : all;
    result.add(finalPool[random.nextInt(finalPool.length)]);

    // Shuffle so the guaranteed fitting piece isn't always in slot 0
    result.shuffle(random);
    return result;
  }
}
