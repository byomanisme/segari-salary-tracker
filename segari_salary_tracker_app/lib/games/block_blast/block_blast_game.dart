import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'block_shape.dart';

class BonusTile {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final int bonusPoints;

  const BonusTile({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.bonusPoints,
  });

  static const List<BonusTile> availableTypes = [
    BonusTile(
      id: 'gift',
      label: 'Kado Segari',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFEF4444),
      bonusPoints: 150,
    ),
    BonusTile(
      id: 'star',
      label: 'Bintang Emas',
      icon: Icons.star_rounded,
      color: Color(0xFFF59E0B),
      bonusPoints: 120,
    ),
    BonusTile(
      id: 'diamond',
      label: 'Berlian Segari',
      icon: Icons.diamond_rounded,
      color: Color(0xFF06B6D4),
      bonusPoints: 200,
    ),
    BonusTile(
      id: 'coin',
      label: 'Koin Emas',
      icon: Icons.monetization_on_rounded,
      color: Color(0xFF10B981),
      bonusPoints: 100,
    ),
  ];
}

class BlastResult {
  final List<int> clearedRows;
  final List<int> clearedCols;
  final int basePoints;
  final int randomBonus;
  final int specialBonusPoints;
  final List<BonusTile> collectedBonusTiles;
  final int pointsEarned;
  final int combo;
  final String comboMessage;
  final int bonusSeconds;
  final bool isPerfectClear;
  final int timestamp;

  BlastResult({
    required this.clearedRows,
    required this.clearedCols,
    required this.basePoints,
    required this.randomBonus,
    this.specialBonusPoints = 0,
    this.collectedBonusTiles = const [],
    required this.pointsEarned,
    required this.combo,
    required this.comboMessage,
    this.bonusSeconds = 0,
    this.isPerfectClear = false,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;
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

  // Mystery Bonus Cells on empty board cells (key: "r-c")
  final Map<String, BonusTile> bonusCells = {};

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
    bonusCells.clear();
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
    _spawnBonusTiles(3);
    startTimer();
  }

  void _spawnBonusTiles(int count) {
    final emptyCells = <Point<int>>[];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == null && !bonusCells.containsKey('$r-$c')) {
          emptyCells.add(Point(r, c));
        }
      }
    }
    emptyCells.shuffle(_random);
    final toSpawn = min(count, emptyCells.length);
    for (int i = 0; i < toSpawn; i++) {
      final pt = emptyCells[i];
      final tile = BonusTile.availableTypes[_random.nextInt(BonusTile.availableTypes.length)];
      bonusCells['${pt.x}-${pt.y}'] = tile;
    }
  }

  void _ensureBonusTiles() {
    int emptyCount = 0;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == null) emptyCount++;
      }
    }
    // Maintain 2 to 3 bonus tiles if enough empty space exists
    if (bonusCells.length < 3 && emptyCount > 5) {
      _spawnBonusTiles(3 - bonusCells.length);
    }
  }

  void startTimer() {
    _stopTimer();
    isTimerRunning = true;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        _stopTimer();
        isGameOver = true;
        _saveHighScore();
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
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

    // 3. Clear lines & award blast score with combo multiplier + mystery tile bonus!
    final totalLines = rowsToClear.length + colsToClear.length;
    if (totalLines > 0) {
      combo++;
      final baseBonus = totalLines * 100;
      final comboBonus = combo * 50;

      // Check for Mystery Bonus Tiles in the cleared lines!
      int specialBonusPoints = 0;
      final collectedTiles = <BonusTile>[];
      final clearedKeys = <String>{};

      for (final r in rowsToClear) {
        for (int c = 0; c < boardSize; c++) {
          final key = '$r-$c';
          if (bonusCells.containsKey(key) && !clearedKeys.contains(key)) {
            clearedKeys.add(key);
            final tile = bonusCells.remove(key)!;
            specialBonusPoints += tile.bonusPoints;
            collectedTiles.add(tile);
          }
        }
      }

      for (final c in colsToClear) {
        for (int r = 0; r < boardSize; r++) {
          final key = '$r-$c';
          if (bonusCells.containsKey(key) && !clearedKeys.contains(key)) {
            clearedKeys.add(key);
            final tile = bonusCells.remove(key)!;
            specialBonusPoints += tile.bonusPoints;
            collectedTiles.add(tile);
          }
        }
      }

      // Random lucky bonus points on every line blast (25 to 150 points)
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
      final totalBlastPoints = baseBonus + comboBonus + randomBonusPoints + specialBonusPoints + perfectClearBonus;

      score += totalBlastPoints;
      _addExp(totalBlastPoints);

      // Extra time bonus for line blast! (+5 seconds per line cleared)
      final bonusTime = totalLines * 5 + (isPerfect ? 15 : 0);
      remainingSeconds += bonusTime;

      String message = 'BLAST! 💥';
      if (collectedTiles.isNotEmpty) {
        message = '${collectedTiles.first.label} +$specialBonusPoints! 🎁';
      } else if (isPerfect) {
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
        specialBonusPoints: specialBonusPoints,
        collectedBonusTiles: collectedTiles,
        pointsEarned: totalBlastPoints,
        combo: combo,
        comboMessage: message,
        bonusSeconds: bonusTime,
        isPerfectClear: isPerfect,
      );

      // Respawn bonus tiles on new empty cells
      _ensureBonusTiles();
    } else {
      combo = 0;
      lastBlast = null;
    }

    _saveHighScore();

    // If tray is empty, refill with 3 new pieces
    if (currentPieces.every((p) => p == null)) {
      _refillPieces();
    } else {
      _checkGameOver();
    }

    notifyListeners();
    return true;
  }

  void _checkGameOver() {
    if (isGameOver) return;

    bool canPlaceAny = false;
    for (final piece in currentPieces) {
      if (piece == null) continue;

      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (canPlace(piece, r, c)) {
            canPlaceAny = true;
            break;
          }
        }
        if (canPlaceAny) break;
      }
      if (canPlaceAny) break;
    }

    if (!canPlaceAny && currentPieces.any((p) => p != null)) {
      isGameOver = true;
      _stopTimer();
      _saveHighScore();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
