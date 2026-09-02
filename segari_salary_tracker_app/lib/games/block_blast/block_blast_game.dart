import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'block_shape.dart';

class BlastResult {
  final List<int> clearedRows;
  final List<int> clearedCols;
  final int basePoints;
  final int randomBonus;
  final int pointsEarned;
  final int combo;
  final String comboMessage;
  final int bonusSeconds;
  final bool isPerfectClear;

  BlastResult({
    required this.clearedRows,
    required this.clearedCols,
    required this.basePoints,
    required this.randomBonus,
    required this.pointsEarned,
    required this.combo,
    required this.comboMessage,
    this.bonusSeconds = 0,
    this.isPerfectClear = false,
  });
}

class BlockBlastGame extends ChangeNotifier {
  static const int boardSize = 8;
  static const String _prefHighScoreKey = 'segari_block_blast_high_score';
  final Random _random = Random();

  late List<List<Color?>> board;
  List<BlockShape?> currentPieces = [null, null, null];
  int score = 0;
  int highScore = 0;
  int combo = 0;
  bool isGameOver = false;
  BlastResult? lastBlast;

  // Level & EXP System
  int level = 1;
  int currentExp = 0;
  int expToNextLevel = 300;
  bool hasLevelUp = false;

  // Shift Countdown Timer (Seconds)
  static const int initialTimerSeconds = 90;
  int remainingSeconds = initialTimerSeconds;
  Timer? _countdownTimer;
  bool isTimerRunning = false;

  String get levelTitle {
    switch (level) {
      case 1:
        return 'Junior Picker DW';
      case 2:
        return 'Packing Specialist';
      case 3:
        return 'Senior QC Checker';
      case 4:
        return 'Shift Dispatcher';
      default:
        return 'Warehouse Master Segari';
    }
  }

  double get expProgress {
    if (expToNextLevel <= 0) return 1.0;
    return (currentExp / expToNextLevel).clamp(0.0, 1.0);
  }

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
    level = 1;
    currentExp = 0;
    expToNextLevel = 300;
    hasLevelUp = false;
    remainingSeconds = initialTimerSeconds;
    isGameOver = false;
    lastBlast = null;

    _stopTimer();
    _loadHighScore();
    _refillPieces();
    startTimer();
  }

  void startTimer() {
    _countdownTimer?.cancel();
    isTimerRunning = true;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isGameOver) {
        timer.cancel();
        isTimerRunning = false;
        return;
      }

      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        isGameOver = true;
        timer.cancel();
        isTimerRunning = false;
        _saveHighScore();
        notifyListeners();
      }
    });
  }

  void pauseTimer() {
    _countdownTimer?.cancel();
    isTimerRunning = false;
  }

  void resumeTimer() {
    if (!isGameOver && !isTimerRunning) {
      startTimer();
    }
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    isTimerRunning = false;
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

  void _addExp(int amount) {
    currentExp += amount;
    hasLevelUp = false;

    while (currentExp >= expToNextLevel) {
      currentExp -= expToNextLevel;
      level++;
      expToNextLevel = (expToNextLevel * 1.4).round();
      remainingSeconds += 15; // Bonus 15 seconds for Level Up!
      // Level up bonus points
      final lvlBonus = level * 150;
      score += lvlBonus;
      hasLevelUp = true;
    }
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
    if (isGameOver) return false;
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

    // Award placement score with occasional lucky bonus (25% chance)
    int basePlacedPoints = shape.blockCount * 10;
    int randomPlacementBonus = (_random.nextInt(4) == 0) ? (_random.nextInt(5) + 1) * 15 : 0;
    int totalPlaced = basePlacedPoints + randomPlacementBonus;

    score += totalPlaced;
    _addExp(totalPlaced);
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

    // 3. Clear lines & award blast score with combo multiplier + random bonus!
    final totalLines = rowsToClear.length + colsToClear.length;
    if (totalLines > 0) {
      combo++;
      final baseBonus = totalLines * 100;
      final comboBonus = combo * 50;

      // Random lucky bonus points on every line blast (30 to 150 points)!
      final randomBonusPoints = (_random.nextInt(6) + 1) * 25;

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

      // Check if board is 100% clean (Perfect Clear bonus!)
      bool isPerfect = true;
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (board[r][c] != null) {
            isPerfect = false;
            break;
          }
        }
        if (!isPerfect) break;
      }

      int perfectClearBonus = isPerfect ? 800 : 0;
      final totalBlastPoints = baseBonus + comboBonus + randomBonusPoints + perfectClearBonus;

      score += totalBlastPoints;
      _addExp(totalBlastPoints);

      // Extra time bonus for line blast! (+5 seconds per line cleared)
      final bonusTime = totalLines * 5 + (isPerfect ? 15 : 0);
      remainingSeconds += bonusTime;

      String message = 'BLAST! 💥';
      if (isPerfect) {
        message = 'PERFECT CLEAR! 👑 +800';
      } else if (combo >= 4) {
        message = 'SUPER COMBO x$combo! 🔥';
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
        basePoints: baseBonus + comboBonus,
        randomBonus: randomBonusPoints + perfectClearBonus,
        pointsEarned: totalBlastPoints,
        combo: combo,
        comboMessage: message,
        bonusSeconds: bonusTime,
        isPerfectClear: isPerfect,
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
    _stopTimer();
    _saveHighScore();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
