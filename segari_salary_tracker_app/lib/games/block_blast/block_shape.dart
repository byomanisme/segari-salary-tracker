import 'dart:math';
import 'package:flutter/material.dart';

class BlockShape {
  final String id;
  final List<List<int>> matrix;
  final Color color;

  const BlockShape({
    required this.id,
    required this.matrix,
    required this.color,
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
  static const Color blue = Color(0xFF3B82F6);    // Blue Gem

  static List<BlockShape> getAllShapes() {
    return [
      // 1x1 Single
      const BlockShape(
        id: 'dot_1',
        matrix: [[1]],
        color: amber,
      ),

      // 2x1 and 1x2 Domino
      const BlockShape(
        id: 'h_line_2',
        matrix: [[1, 1]],
        color: cyan,
      ),
      const BlockShape(
        id: 'v_line_2',
        matrix: [[1], [1]],
        color: cyan,
      ),

      // 3x1 and 1x3 Line
      const BlockShape(
        id: 'h_line_3',
        matrix: [[1, 1, 1]],
        color: emerald,
      ),
      const BlockShape(
        id: 'v_line_3',
        matrix: [[1], [1], [1]],
        color: emerald,
      ),

      // 4x1 and 1x4 Line
      const BlockShape(
        id: 'h_line_4',
        matrix: [[1, 1, 1, 1]],
        color: blue,
      ),
      const BlockShape(
        id: 'v_line_4',
        matrix: [[1], [1], [1], [1]],
        color: blue,
      ),

      // 5x1 and 1x5 Line
      const BlockShape(
        id: 'h_line_5',
        matrix: [[1, 1, 1, 1, 1]],
        color: purple,
      ),
      const BlockShape(
        id: 'v_line_5',
        matrix: [[1], [1], [1], [1], [1]],
        color: purple,
      ),

      // 2x2 Square
      const BlockShape(
        id: 'sq_2',
        matrix: [
          [1, 1],
          [1, 1],
        ],
        color: orange,
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
      ),

      // Small Corner (3 blocks)
      const BlockShape(
        id: 'corner_tl',
        matrix: [
          [1, 1],
          [1, 0],
        ],
        color: emerald,
      ),
      const BlockShape(
        id: 'corner_tr',
        matrix: [
          [1, 1],
          [0, 1],
        ],
        color: emerald,
      ),
      const BlockShape(
        id: 'corner_bl',
        matrix: [
          [1, 0],
          [1, 1],
        ],
        color: emerald,
      ),
      const BlockShape(
        id: 'corner_br',
        matrix: [
          [0, 1],
          [1, 1],
        ],
        color: emerald,
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
      ),
      const BlockShape(
        id: 'l_down_left',
        matrix: [
          [0, 1],
          [0, 1],
          [1, 1],
        ],
        color: amber,
      ),
      const BlockShape(
        id: 'l_up_right',
        matrix: [
          [1, 1],
          [1, 0],
          [1, 0],
        ],
        color: amber,
      ),
      const BlockShape(
        id: 'l_up_left',
        matrix: [
          [1, 1],
          [0, 1],
          [0, 1],
        ],
        color: amber,
      ),

      // T-Shapes
      const BlockShape(
        id: 't_down',
        matrix: [
          [1, 1, 1],
          [0, 1, 0],
        ],
        color: purple,
      ),
      const BlockShape(
        id: 't_up',
        matrix: [
          [0, 1, 0],
          [1, 1, 1],
        ],
        color: purple,
      ),
      const BlockShape(
        id: 't_right',
        matrix: [
          [1, 0],
          [1, 1],
          [1, 0],
        ],
        color: purple,
      ),
      const BlockShape(
        id: 't_left',
        matrix: [
          [0, 1],
          [1, 1],
          [0, 1],
        ],
        color: purple,
      ),

      // Z & S shapes
      const BlockShape(
        id: 'z_shape',
        matrix: [
          [1, 1, 0],
          [0, 1, 1],
        ],
        color: rose,
      ),
      const BlockShape(
        id: 's_shape',
        matrix: [
          [0, 1, 1],
          [1, 1, 0],
        ],
        color: cyan,
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
