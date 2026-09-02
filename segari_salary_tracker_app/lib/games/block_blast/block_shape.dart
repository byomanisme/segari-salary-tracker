import 'dart:math';
import 'package:flutter/material.dart';

class BlockShape {
  final String id;
  final List<List<int>> matrix;
  final Color color;
  final IconData icon;
  final String label;

  const BlockShape({
    required this.id,
    required this.matrix,
    required this.color,
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
  static const Color emerald = Color(0xFF10B981); // Sayuran Segari
  static const Color cyan = Color(0xFF06B6D4);    // Pagi / Air Segar
  static const Color amber = Color(0xFFF59E0B);   // Jeruk / Lemon
  static const Color orange = Color(0xFFF97316);  // Wortel Segari
  static const Color purple = Color(0xFF8B5CF6);  // Terong / Anggur
  static const Color rose = Color(0xFFF43F5E);    // Tomat / Stroberi
  static const Color blue = Color(0xFF3B82F6);    // Blue Gem Segari

  static IconData getIconForColor(Color color) {
    if (color.value == emerald.value) return Icons.eco_rounded;
    if (color.value == orange.value) return Icons.agriculture_rounded;
    if (color.value == amber.value) return Icons.wb_sunny_rounded;
    if (color.value == rose.value) return Icons.favorite_rounded;
    if (color.value == purple.value) return Icons.bubble_chart_rounded;
    if (color.value == cyan.value) return Icons.water_drop_rounded;
    return Icons.diamond_rounded;
  }

  static String getLabelForColor(Color color) {
    if (color.value == emerald.value) return 'Sayur Hijau Segari';
    if (color.value == orange.value) return 'Wortel Segari';
    if (color.value == amber.value) return 'Lemon Segari';
    if (color.value == rose.value) return 'Tomat Segar';
    if (color.value == purple.value) return 'Terong & Anggur';
    if (color.value == cyan.value) return 'Air Mineral Segari';
    return 'Paket Segari';
  }

  static List<BlockShape> getAllShapes() {
    return [
      // 1x1 Single
      const BlockShape(
        id: 'dot_1',
        matrix: [[1]],
        color: amber,
        icon: Icons.wb_sunny_rounded,
        label: 'Lemon Segar',
      ),

      // 2x1 and 1x2 Domino
      const BlockShape(
        id: 'h_line_2',
        matrix: [[1, 1]],
        color: cyan,
        icon: Icons.water_drop_rounded,
        label: 'Air Mineral Segar',
      ),
      const BlockShape(
        id: 'v_line_2',
        matrix: [[1], [1]],
        color: cyan,
        icon: Icons.water_drop_rounded,
        label: 'Air Mineral Segar',
      ),

      // 3x1 and 1x3 Line
      const BlockShape(
        id: 'h_line_3',
        matrix: [[1, 1, 1]],
        color: emerald,
        icon: Icons.eco_rounded,
        label: 'Sawi Hijau Segari',
      ),
      const BlockShape(
        id: 'v_line_3',
        matrix: [[1], [1], [1]],
        color: emerald,
        icon: Icons.eco_rounded,
        label: 'Sawi Hijau Segari',
      ),

      // 4x1 and 1x4 Line
      const BlockShape(
        id: 'h_line_4',
        matrix: [[1, 1, 1, 1]],
        color: blue,
        icon: Icons.diamond_rounded,
        label: 'Paket Sayur Premium',
      ),
      const BlockShape(
        id: 'v_line_4',
        matrix: [[1], [1], [1], [1]],
        color: blue,
        icon: Icons.diamond_rounded,
        label: 'Paket Sayur Premium',
      ),

      // 5x1 and 1x5 Line
      const BlockShape(
        id: 'h_line_5',
        matrix: [[1, 1, 1, 1, 1]],
        color: purple,
        icon: Icons.bubble_chart_rounded,
        label: 'Anggur Segari',
      ),
      const BlockShape(
        id: 'v_line_5',
        matrix: [[1], [1], [1], [1], [1]],
        color: purple,
        icon: Icons.bubble_chart_rounded,
        label: 'Anggur Segari',
      ),

      // 2x2 Square
      const BlockShape(
        id: 'sq_2',
        matrix: [
          [1, 1],
          [1, 1],
        ],
        color: orange,
        icon: Icons.agriculture_rounded,
        label: 'Wortel Segari',
      ),

      // 3x3 Square
      const BlockShape(
        id: 'sq_3',
        matrix: [
          [1, 1, 1],
          [1, 1, 1],
          [1, 1, 1],
        ],
        color: rose,
        icon: Icons.favorite_rounded,
        label: 'Tomat Segar',
      ),

      // Small Corner (3 blocks)
      const BlockShape(
        id: 'corner_tl',
        matrix: [
          [1, 1],
          [1, 0],
        ],
        color: emerald,
        icon: Icons.eco_rounded,
        label: 'Selada Segari',
      ),
      const BlockShape(
        id: 'corner_tr',
        matrix: [
          [1, 1],
          [0, 1],
        ],
        color: emerald,
        icon: Icons.eco_rounded,
        label: 'Selada Segari',
      ),
      const BlockShape(
        id: 'corner_bl',
        matrix: [
          [1, 0],
          [1, 1],
        ],
        color: emerald,
        icon: Icons.eco_rounded,
        label: 'Selada Segari',
      ),
      const BlockShape(
        id: 'corner_br',
        matrix: [
          [0, 1],
          [1, 1],
        ],
        color: emerald,
        icon: Icons.eco_rounded,
        label: 'Selada Segari',
      ),

      // Big L-Shapes (4 blocks)
      const BlockShape(
        id: 'l_down_right',
        matrix: [
          [1, 0],
          [1, 0],
          [1, 1],
        ],
        color: amber,
        icon: Icons.wb_sunny_rounded,
        label: 'Jagung Manis',
      ),
      const BlockShape(
        id: 'l_down_left',
        matrix: [
          [0, 1],
          [0, 1],
          [1, 1],
        ],
        color: amber,
        icon: Icons.wb_sunny_rounded,
        label: 'Jagung Manis',
      ),
      const BlockShape(
        id: 'l_up_right',
        matrix: [
          [1, 1],
          [1, 0],
          [1, 0],
        ],
        color: amber,
        icon: Icons.wb_sunny_rounded,
        label: 'Jagung Manis',
      ),
      const BlockShape(
        id: 'l_up_left',
        matrix: [
          [1, 1],
          [0, 1],
          [0, 1],
        ],
        color: amber,
        icon: Icons.wb_sunny_rounded,
        label: 'Jagung Manis',
      ),

      // T-Shapes
      const BlockShape(
        id: 't_down',
        matrix: [
          [1, 1, 1],
          [0, 1, 0],
        ],
        color: purple,
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),
      const BlockShape(
        id: 't_up',
        matrix: [
          [0, 1, 0],
          [1, 1, 1],
        ],
        color: purple,
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),
      const BlockShape(
        id: 't_right',
        matrix: [
          [1, 0],
          [1, 1],
          [1, 0],
        ],
        color: purple,
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),
      const BlockShape(
        id: 't_left',
        matrix: [
          [0, 1],
          [1, 1],
          [0, 1],
        ],
        color: purple,
        icon: Icons.bubble_chart_rounded,
        label: 'Terong Ungu',
      ),

      // Z & S shapes
      const BlockShape(
        id: 'z_shape',
        matrix: [
          [1, 1, 0],
          [0, 1, 1],
        ],
        color: rose,
        icon: Icons.favorite_rounded,
        label: 'Stroberi Segari',
      ),
      const BlockShape(
        id: 's_shape',
        matrix: [
          [0, 1, 1],
          [1, 1, 0],
        ],
        color: cyan,
        icon: Icons.water_drop_rounded,
        label: 'Kelapa Muda',
      ),
    ];
  }

  static List<BlockShape> getRandomSet(int count) {
    final all = getAllShapes();
    final random = Random();
    final result = <BlockShape>[];
    for (int i = 0; i < count; i++) {
      result.add(all[random.nextInt(all.length)]);
    }
    return result;
  }
}
