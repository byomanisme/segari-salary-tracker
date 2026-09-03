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

class SlitheringMascot {
  final String skinId; // 'caterpillar' or 'snake'
  final String name;
  final String emoji;
  final List<Point<int>> body; // [head, body, tail]
  Point<int> direction; // e.g. Point(1, 0)
  int animTick;
  int stepsRemaining;
  final int bonusPoints;

  SlitheringMascot({
    required this.skinId,
    required this.name,
    required this.emoji,
    required this.body,
    required this.direction,
    this.animTick = 0,
    this.stepsRemaining = 18,
    required this.bonusPoints,
  });

  bool occupies(int r, int c) {
    return body.any((pt) => pt.x == r && pt.y == c);
  }

  int indexOf(int r, int c) {
    return body.indexWhere((pt) => pt.x == r && pt.y == c);
  }
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

  // Slithering Mascot (Ulat Sayur & Ular Segari)
  SlitheringMascot? currentMascot;
  Timer? _cameoTimer;
  Timer? _slitherTimer;
  void Function(String skinId, int r, int c)? onMascotStepped;
  void Function(String skinId)? onMascotSpawned;

  // Dynamic Segari Fun Facts Database
  static const List<String> segariFunFacts = [
    '🥦 Brokoli kaya vitamin C & sulforaphane, simpan di chiller dalam wadah tertutup agar tetap renyah!',
    '🥕 Wortel Brastagi Segari manis alami karena dipanen dari dataran tinggi tanah vulkanis gembur.',
    '🐟 Ikan Salmon Segari kaya Omega-3, simpan beku di freezer maksimal -18°C untuk kesegaran optimal.',
    '🥬 Tips: Rendam selada yang agak layu di air es selama 5 menit agar garing dan segar kembali!',
    '🥩 Daging Sapi Segari diproses rantai dingin (cold chain) higienis tanpa bahan pengawet.',
    '🍌 Pisang Cavendish menghasilkan gas etilen alami, jangan disimpan dekat sayur hijau agar sayur awet.',
    '🍅 Tomat merah kaya antioksidan likopen yang makin mudah diserap tubuh saat dimasak.',
    '🌽 Jagung manis Segari memiliki kadar gula alami tinggi saat baru dipetik dari ladang mitra.',
    '🍆 Terong ungu Segari kaya nasunin pada kulitnya yang bermanfaat melindungi sel-sel tubuh.',
    '🍗 Ayam potong Segari diproses bersih halal dan segera didinginkan di ruang steril pendingin.',
    '🦐 Udang Vaname Segari berdaging kenyal manis, simpan di chiller dialasi es batu serut.',
    '🍊 Jeruk Segari diperas langsung memberi asupan 100% vitamin C harian untuk imunitas tubuh.',
    '🍎 Apel Fuji Segari renyah manis, simpan di laci bawah kulkas agar kelembapannya terjaga.',
    '🍇 Anggur merah Segari kaya resveratrol, cuci hanya saat hendak dimakan agar tidak mudah lembek.',
    '🍓 Stroberi Ciwidey Segari harum manis, jangan buang tangkainya sebelum dicuci agar air tak masuk.',
    '🧅 Bawang merah Brebes Segari beraroma tajam harum khas yang bikin aneka masakan jadi sedap.',
    '🧄 Bawang putih Kating Segari memiliki siung padat dengan kandungan allicin alami tinggi.',
    '🥔 Kentang Dieng Segari pulen alami, jangan simpan di kulkas agar patinya tidak berubah jadi gula.',
    '🍄 Jamur tiram segar Segari kaya serat beta-glukan, simpan dalam kantong kertas di kulkas.',
    '🫑 Paprika merah Segari mengandung vitamin C tiga kali lebih banyak dibanding buah jeruk!',
    '🥚 Telur Omega-3 Segari memiliki kuning telur jingga cerah kaya nutrisi untuk sarapan bertenaga.',
  ];
  String currentFunFact = segariFunFacts[0];

  // Level & EXP System
  int level = 1;
  int currentExp = 0;
  int expToNextLevel = 300;
  bool hasLevelUp = false;

  // Game Mode: Untimed Classic (default like real Block Blast) vs Time Attack
  bool isTimeAttackMode = false;
  bool canRevive = true;
  int comboGraceTurns = 0;

  // Shift Countdown Timer (Seconds, only used in Time Attack Mode)
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

  BlockBlastGame({bool timeAttack = false}) {
    isTimeAttackMode = timeAttack;
    initGame();
  }

  void toggleTimeMode() {
    isTimeAttackMode = !isTimeAttackMode;
    if (isTimeAttackMode) {
      remainingSeconds = initialTimerSeconds;
      startTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  void initGame() {
    board = List.generate(
      boardSize,
      (_) => List.generate(boardSize, (_) => null),
    );
    bonusCells.clear();
    currentMascot = null;
    score = 0;
    combo = 0;
    comboGraceTurns = 0;
    level = 1;
    currentExp = 0;
    expToNextLevel = 300;
    hasLevelUp = false;
    remainingSeconds = initialTimerSeconds;
    isGameOver = false;
    canRevive = true;
    lastBlast = null;
    currentFunFact = segariFunFacts[_random.nextInt(segariFunFacts.length)];

    _stopTimer();
    _stopMascotTimers();
    _loadHighScore();
    _refillPieces();
    _spawnBonusTiles(3);
    if (isTimeAttackMode) {
      startTimer();
    }
    _startCameoTimer();
  }

  /// Second Chance / Revive: Clears central 4x4 area to save high score!
  void reviveGame() {
    if (!canRevive) return;
    canRevive = false;
    isGameOver = false;

    // Clear center 4x4 area (rows 2-5, cols 2-5)
    for (int r = 2; r <= 5; r++) {
      for (int c = 2; c <= 5; c++) {
        board[r][c] = null;
      }
    }

    if (isTimeAttackMode) {
      remainingSeconds += 30;
      startTimer();
    }

    // Ensure pieces can fit
    _refillPieces();
    _startCameoTimer();
    notifyListeners();
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
    if (bonusCells.length < 3 && emptyCount > 5) {
      _spawnBonusTiles(3 - bonusCells.length);
    }
  }

  // --- Slithering Mascot Engine (Ulat Sayur 🐛 & Ular Hijau 🐍) ---
  void _startCameoTimer() {
    _stopMascotTimers();
    // Spawn cameo mascot every 15 to 22 seconds
    final delay = 15 + _random.nextInt(8);
    _cameoTimer = Timer(Duration(seconds: delay), _spawnMascot);
  }

  void _stopMascotTimers() {
    _cameoTimer?.cancel();
    _cameoTimer = null;
    _slitherTimer?.cancel();
    _slitherTimer = null;
  }

  void _spawnMascot() {
    if (isGameOver) return;

    // Find a cluster of 2-3 connected empty cells
    final emptyCells = <Point<int>>[];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == null && !bonusCells.containsKey('$r-$c')) {
          emptyCells.add(Point(r, c));
        }
      }
    }

    if (emptyCells.length < 3) {
      _startCameoTimer();
      return;
    }

    emptyCells.shuffle(_random);
    Point<int>? startPt;
    Point<int>? secondPt;
    Point<int>? thirdPt;

    final dirs = [
      const Point(1, 0),
      const Point(-1, 0),
      const Point(0, 1),
      const Point(0, -1),
    ];

    for (final pt in emptyCells) {
      for (final d in dirs) {
        final p2 = Point(pt.x + d.x, pt.y + d.y);
        if (p2.x >= 0 && p2.x < boardSize && p2.y >= 0 && p2.y < boardSize &&
            board[p2.x][p2.y] == null && !bonusCells.containsKey('${p2.x}-${p2.y}')) {
          for (final d2 in dirs) {
            final p3 = Point(p2.x + d2.x, p2.y + d2.y);
            if (p3 != pt && p3.x >= 0 && p3.x < boardSize && p3.y >= 0 && p3.y < boardSize &&
                board[p3.x][p3.y] == null && !bonusCells.containsKey('${p3.x}-${p3.y}')) {
              startPt = pt;
              secondPt = p2;
              thirdPt = p3;
              break;
            }
          }
        }
        if (startPt != null) break;
      }
      if (startPt != null) break;
    }

    if (startPt != null && secondPt != null && thirdPt != null) {
      final isCaterpillar = _random.nextBool();
      final initialDir = Point(startPt.x - secondPt.x, startPt.y - secondPt.y);

      currentMascot = SlitheringMascot(
        skinId: isCaterpillar ? 'caterpillar' : 'snake',
        name: isCaterpillar ? 'Ulat Sayur Segari' : 'Ular Hijau Segari',
        emoji: isCaterpillar ? '🐛' : '🐍',
        body: [startPt, secondPt, thirdPt],
        direction: initialDir.x == 0 && initialDir.y == 0 ? const Point(1, 0) : initialDir,
        stepsRemaining: 20,
        bonusPoints: 75 + _random.nextInt(3) * 25, // 75, 100, 125
      );
      onMascotSpawned?.call(currentMascot!.skinId);
      notifyListeners();

      // Start stepping timer (slithers every 380ms)
      _slitherTimer?.cancel();
      _slitherTimer = Timer.periodic(const Duration(milliseconds: 380), (_) {
        _stepMascot();
      });
    } else {
      _startCameoTimer();
    }
  }

  void _stepMascot() {
    if (currentMascot == null || isGameOver) {
      _slitherTimer?.cancel();
      return;
    }

    final m = currentMascot!;
    if (m.stepsRemaining <= 0) {
      // Slithered away safely into the garden!
      currentMascot = null;
      _stopMascotTimers();
      _startCameoTimer();
      notifyListeners();
      return;
    }

    m.stepsRemaining--;
    m.animTick++;

    final head = m.body.first;
    // Prefer going straight, then turn right, then turn left
    final possibleDirs = [
      m.direction,
      Point(-m.direction.y, m.direction.x),
      Point(m.direction.y, -m.direction.x),
    ];

    Point<int>? nextHead;
    Point<int>? nextDir;

    for (final dir in possibleDirs) {
      final nextPt = Point(head.x + dir.x, head.y + dir.y);
      if (nextPt.x >= 0 && nextPt.x < boardSize &&
          nextPt.y >= 0 && nextPt.y < boardSize &&
          board[nextPt.x][nextPt.y] == null &&
          !m.body.contains(nextPt)) {
        nextHead = nextPt;
        nextDir = dir;
        break;
      }
    }

    if (nextHead != null && nextDir != null) {
      m.direction = nextDir;
      m.body.insert(0, nextHead);
      if (m.body.length > 3) {
        m.body.removeLast();
      }
      onMascotStepped?.call(m.skinId, nextHead.x, nextHead.y);
      notifyListeners();
    } else {
      // Reached a dead end, burrows away peacefully!
      currentMascot = null;
      _stopMascotTimers();
      _startCameoTimer();
      notifyListeners();
    }
  }

  /// Interact with slithering mascot when any of its segments is tapped
  int? interactMascot(int r, int c) {
    if (currentMascot == null || !currentMascot!.occupies(r, c)) return null;

    final pts = currentMascot!.bonusPoints;
    score += pts;
    _addExp(pts);
    _saveHighScore();

    currentMascot = null;
    _stopMascotTimers();
    notifyListeners();

    _startCameoTimer();
    return pts;
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
        _stopMascotTimers();
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
    currentPieces = List<BlockShape?>.from(BlockShape.getSmartSet(board));
    _checkGameOver();
  }

  void _addExp(int amount) {
    currentExp += amount;

    while (currentExp >= expToNextLevel) {
      currentExp -= expToNextLevel;
      level++;
      expToNextLevel = (expToNextLevel * 1.4).round();
      remainingSeconds += 15;
      final lvlBonus = level * 150;
      score += lvlBonus;
      hasLevelUp = true;
    }
  }

  void consumeLevelUp() {
    hasLevelUp = false;
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
          if (targetR >= boardSize || targetC >= boardSize) return false;
          // STRICT NO-OVERWRITE: cell must be completely null
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

    // Strict validation: NEVER place if canPlace is false
    if (!canPlace(shape, startRow, startCol)) return false;

    // If mascot was occupying any of the placed cells, collect it automatically!
    for (int r = 0; r < shape.rows; r++) {
      for (int c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c] == 1) {
          final targetR = startRow + r;
          final targetC = startCol + c;
          if (currentMascot != null && currentMascot!.occupies(targetR, targetC)) {
            interactMascot(targetR, targetC);
          }
          board[targetR][targetC] = shape.color;
        }
      }
    }

    // Update dynamic Fun Fact on every block placed!
    currentFunFact = segariFunFacts[_random.nextInt(segariFunFacts.length)];

    // Award placement score with lucky bonus (25% chance)
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
      comboGraceTurns = 1; // 1 setup move grace period
      final baseBonus = totalLines * 100;
      final comboBonus = combo * 50;

      // Check for Mystery Bonus Tiles in the cleared lines
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

      // Check if board is 100% clean (Perfect Clear bonus)
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

      _ensureBonusTiles();
    } else {
      if (comboGraceTurns > 0) {
        comboGraceTurns--;
      } else {
        combo = 0;
      }
      lastBlast = null;
    }

    _saveHighScore();

    if (currentPieces.every((p) => p == null)) {
      _refillPieces();
    } else {
      _checkGameOver();
    }

    notifyListeners();
    return true;
  }

  /// Comprehensive scanning to detect Game Over accurately
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

    // Only trigger game over if pieces remain but NONE of them fit anywhere
    if (!canPlaceAny && currentPieces.any((p) => p != null)) {
      isGameOver = true;
      _stopTimer();
      _stopMascotTimers();
      _saveHighScore();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _stopMascotTimers();
    super.dispose();
  }
}
