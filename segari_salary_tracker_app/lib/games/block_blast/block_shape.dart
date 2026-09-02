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
    final v = color.value;
    if (v == emerald.value) return '🥦';
    if (v == orange.value) return '🥕';
    if (v == rose.value) return '🍅';
    if (v == amber.value) return '🌽';
    if (v == purple.value) return '🍆';
    if (v == cyan.value) return '🐟';
    if (v == blue.value) return '🥩';
    return '🥬';
  }

  static IconData getIconForColor(Color color) {
    final v = color.value;
    if (v == emerald.value) return Icons.eco_rounded;
    if (v == orange.value) return Icons.agriculture_rounded;
    if (v == rose.value) return Icons.favorite_rounded;
    if (v == amber.value) return Icons.wb_sunny_rounded;
    if (v == purple.value) return Icons.bubble_chart_rounded;
    if (v == cyan.value) return Icons.set_meal_rounded;
    return Icons.restaurant_rounded;
  }

  static String getLabelForColor(Color color) {
    final v = color.value;
    if (v == emerald.value) return 'Brokoli Hijau Segari 🥦';
    if (v == orange.value) return 'Wortel Brastagi 🥕';
    if (v == rose.value) return 'Tomat Merah Lembang 🍅';
    if (v == amber.value) return 'Jagung Manis Segari 🌽';
    if (v == purple.value) return 'Terong Ungu Segari 🍆';
    if (v == cyan.value) return 'Ikan Salmon Segar 🐟';
    if (v == blue.value) return 'Daging Sapi Segari 🥩';
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

  static List<BlockShape> getRandomSet(int count) {
    final all = getAllShapes();
    final random = Random();
    final set = <BlockShape>[];
    for (int i = 0; i < count; i++) {
      set.add(all[random.nextInt(all.length)]);
    }
    return set;
  }
}
