import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'block_shape.dart';

class BlastResult {
  final List<int> clearedRows;
  final List<int> clearedCols;
  final int pointsEarned;
  final int combo;
  final String comboMessage;

  BlastResult({
    required this.clearedRows,
    required this.clearedCols,
    required this.pointsEarned,
    required this.combo,
    required this.comboMessage,
  });
}

class BlockBlastGame extends ChangeNotifier {
  static const int boardSize = 8;
  static const String _prefHighScoreKey = 'segari_block_blast_high_score';

  late List<List<Color?>> board;
  List<BlockShape?> currentPieces = [null, null, null];
  int score = 0;
  int highScore = 0;
  int combo = 0;
  bool isGameOver = false;
  BlastResult? lastBlast;

  BlockBlastGame() {
    initGame();
  }

  void initGame() {
    board = List.generate(
      boardSize,
      (_) => List.generate(boardSize, (_) => null),
    );
    score = 0;
    combo = 0;
    isGameOver = false;
    lastBlast = null;
    _loadHighScore();
    _refillPieces();
  }

  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      highScore = prefs.getInt(_prefHighScoreKey) ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveHighScore() async {
    if (score > highScore) {
      highScore = score;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefHighScoreKey, highScore);
      } catch (_) {}
    }
  }

  void _refillPieces() {
    currentPieces = List<BlockShape?>.from(BlockShape.getRandomSet(3));
    _checkGameOver();
  }

  bool canPlace(BlockShape shape, int startRow, int startCol) {
    if (startRow < 0 || startCol < 0) return false;
    if (startRow + shape.rows > boardSize || startCol + shape.cols > boardSize) {
      return false;
    }

    for (int r = 0; r < shape.rows; r++) {
      for (int c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c] == 1) {
          final targetR = startRow + r;
          final targetC = startCol + c;
          if (board[targetR][targetC] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool placePiece(int pieceIndex, int startRow, int startCol) {
    if (pieceIndex < 0 || pieceIndex >= currentPieces.length) return false;
    final shape = currentPieces[pieceIndex];
    if (shape == null) return false;

    if (!canPlace(shape, startRow, startCol)) return false;

    // 1. Place blocks onto board
    for (int r = 0; r < shape.rows; r++) {
      for (int c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c] == 1) {
          board[startRow + r][startCol + c] = shape.color;
        }
      }
    }

    // Award placement score
    int placedPoints = shape.blockCount * 10;
    score += placedPoints;
    currentPieces[pieceIndex] = null;

    // 2. Check full rows & columns
    final rowsToClear = <int>[];
    final colsToClear = <int>[];

    for (int r = 0; r < boardSize; r++) {
      bool rowFull = true;
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == null) {
          rowFull = false;
          break;
        }
      }
      if (rowFull) rowsToClear.add(r);
    }

    for (int c = 0; c < boardSize; c++) {
      bool colFull = true;
      for (int r = 0; r < boardSize; r++) {
        if (board[r][c] == null) {
          colFull = false;
          break;
        }
      }
      if (colFull) colsToClear.add(c);
    }

    // 3. Clear lines & award blast score with combo multiplier
    final totalLines = rowsToClear.length + colsToClear.length;
    if (totalLines > 0) {
      combo++;
      final baseBonus = totalLines * 100;
      final comboBonus = combo * 50;
      final linePoints = baseBonus + comboBonus;
      score += linePoints;

      for (final r in rowsToClear) {
        for (int c = 0; c < boardSize; c++) {
          board[r][c] = null;
        }
      }
      for (final c in colsToClear) {
        for (int r = 0; r < boardSize; r++) {
          board[r][c] = null;
        }
      }

      String message = 'BLAST! 💥';
      if (combo >= 4) {
        message = 'SUPER COMBO x$combo! 🔥🔥🔥';
      } else if (combo >= 2) {
        message = 'COMBO x$combo! 🔥';
      } else if (totalLines >= 3) {
        message = 'TRIPLE BLAST! 🌟';
      } else if (totalLines == 2) {
        message = 'DOUBLE BLAST! ✨';
      }

      lastBlast = BlastResult(
        clearedRows: rowsToClear,
        clearedCols: colsToClear,
        pointsEarned: linePoints,
        combo: combo,
        comboMessage: message,
      );
    } else {
      combo = 0;
      lastBlast = null;
    }

    _saveHighScore();

    // 4. Refill if all pieces placed
    if (currentPieces.every((p) => p == null)) {
      _refillPieces();
    } else {
      _checkGameOver();
    }

    notifyListeners();
    return true;
  }

  void _checkGameOver() {
    final available = currentPieces.whereType<BlockShape>().toList();
    if (available.isEmpty) {
      isGameOver = false;
      return;
    }

    // Check if ANY piece can fit ANYWHERE on the board
    for (final shape in available) {
      for (int r = 0; r <= boardSize - shape.rows; r++) {
        for (int c = 0; c <= boardSize - shape.cols; c++) {
          if (canPlace(shape, r, c)) {
            isGameOver = false;
            return;
          }
        }
      }
    }

    // If no piece fits, game over!
    isGameOver = true;
    _saveHighScore();
  }
}
