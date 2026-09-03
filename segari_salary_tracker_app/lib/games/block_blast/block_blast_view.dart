import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/pixel_mascot_painter.dart';
import 'blast_particles.dart';
import 'block_blast_game.dart';
import 'block_shape.dart';

class BlockBlastView extends StatefulWidget {
  final BlockBlastGame game;
  final VoidCallback onMinimize;
  final VoidCallback? onClose;

  const BlockBlastView({
    super.key,
    required this.game,
    required this.onMinimize,
    this.onClose,
  });

  @override
  State<BlockBlastView> createState() => _BlockBlastViewState();
}

class _BlockBlastViewState extends State<BlockBlastView>
    with TickerProviderStateMixin {
  int? _selectedPieceIndex;
  int? _hoverRow;
  int? _hoverCol;
  int? _draggingPieceIndex;
  int? _lastHandledBlastTimestamp;
  int _lastCelebratedLevel = 1;

  final Set<String> _recentlyPlacedCells = {};
  final BlastParticleManager _particleManager = BlastParticleManager();
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _scoreBadgeKey = GlobalKey();

  late AnimationController _comboAnimController;
  late Animation<double> _comboScaleAnim;

  late AnimationController _scoreBounceAnimController;
  late Animation<double> _scoreBounceAnim;

  late AnimationController _timerPulseController;
  late Animation<double> _timerPulseAnim;

  late AnimationController _outlineNeonController;
  late Animation<double> _outlineNeonAnim;

  @override
  void initState() {
    super.initState();
    _lastCelebratedLevel = widget.game.level;
    widget.game.addListener(_onGameUpdated);

    _comboAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _comboScaleAnim = CurvedAnimation(
      parent: _comboAnimController,
      curve: Curves.elasticOut,
    );

    _scoreBounceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scoreBounceAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _scoreBounceAnimController, curve: Curves.elasticOut),
    );

    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _timerPulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _timerPulseController, curve: Curves.easeInOut),
    );

    _outlineNeonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _outlineNeonAnim = Tween<double>(begin: 0.10, end: 0.35).animate(
      CurvedAnimation(parent: _outlineNeonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGameUpdated);
    _comboAnimController.dispose();
    _scoreBounceAnimController.dispose();
    _timerPulseController.dispose();
    _outlineNeonController.dispose();
    _particleManager.dispose();
    super.dispose();
  }

  void _onGameUpdated() {
    final blast = widget.game.lastBlast;
    if (blast != null && blast.timestamp != _lastHandledBlastTimestamp) {
      _lastHandledBlastTimestamp = blast.timestamp;
      _comboAnimController.forward(from: 0.0);

      // Rising tactile & audio cues based on combo progression
      if (blast.combo >= 4) {
        HapticFeedback.vibrate();
      } else if (blast.combo >= 2) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
      SystemSound.play(SystemSoundType.click);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerParticlesForBlast(blast);
      });
    }

    if (widget.game.hasLevelUp && widget.game.level > _lastCelebratedLevel) {
      _lastCelebratedLevel = widget.game.level;
      widget.game.consumeLevelUp();
      HapticFeedback.vibrate();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
        if (gridBox != null) {
          final size = gridBox.size;
          _particleManager.triggerLevelUpAt(
            Offset(size.width / 2, size.height / 2),
            widget.game.level,
          );
        }
      });
    }

    setState(() {});
  }

  Offset _getTargetScorePos() {
    final RenderBox? scoreBox = _scoreBadgeKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox = context.findRenderObject() as RenderBox?;
    if (scoreBox != null && overlayBox != null) {
      final globalPos = scoreBox.localToGlobal(Offset.zero);
      final localPos = overlayBox.globalToLocal(globalPos);
      return Offset(
        localPos.dx + scoreBox.size.width / 2,
        localPos.dy + scoreBox.size.height / 2,
      );
    }
    return const Offset(90, 45);
  }

  void _triggerParticlesForBlast(BlastResult blast) {
    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final size = gridBox.size;
    final cellW = size.width / BlockBlastGame.boardSize;
    final cellH = size.height / BlockBlastGame.boardSize;

    final centers = <Offset>[];
    final colors = <Color>[];

    for (final r in blast.clearedRows) {
      for (int c = 0; c < BlockBlastGame.boardSize; c++) {
        centers.add(Offset(c * cellW + cellW / 2, r * cellH + cellH / 2));
        colors.add(const Color(0xFF10B981));
      }
    }

    for (final c in blast.clearedCols) {
      for (int r = 0; r < BlockBlastGame.boardSize; r++) {
        centers.add(Offset(c * cellW + cellW / 2, r * cellH + cellH / 2));
        colors.add(const Color(0xFF06B6D4));
      }
    }

    String label = blast.comboMessage;
    if (blast.specialBonusPoints > 0) {
      label += ' (🎁 +${blast.specialBonusPoints})';
    } else if (blast.randomBonus > 0) {
      label += ' (✨ +${blast.randomBonus})';
    }

    final targetScorePos = _getTargetScorePos();

    _particleManager.triggerBlastAt(
      cellCenters: centers,
      colors: colors,
      comboText: label,
      points: blast.pointsEarned,
      targetScorePos: targetScorePos,
      onScoreReached: () {
        _scoreBounceAnimController.forward(from: 0.0);
        HapticFeedback.lightImpact();
      },
    );
  }

  // --- Real Block Blast Coordinate Tracker (Laser-Precise 1:1 Alignment) ---
  void _handleDragUpdate(Offset globalPos, BlockShape piece, double cellPx) {
    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final localPos = gridBox.globalToLocal(globalPos);
    final cellStep = cellPx + 3.0; // cellPx + 3px gap between tiles
    const double verticalLift = 65.0; // Piece floats 65px directly above finger

    // Total width and height of floating piece (cells + 3px gaps)
    final totalPieceW = piece.cols * cellPx + (piece.cols - 1) * 3.0;
    final totalPieceH = piece.rows * cellPx + (piece.rows - 1) * 3.0;

    // Top-left corner of the floating piece in gridBox coordinates
    final pieceTopLeftX = localPos.dx - (totalPieceW / 2.0);
    final pieceTopLeftY = localPos.dy - totalPieceH - verticalLift;

    // Grid tiles start at (5.0, 5.0) inside gridBox due to 5px padding
    final relX = pieceTopLeftX - 5.0;
    final relY = pieceTopLeftY - 5.0;

    final targetCol = (relX / cellStep).round();
    final targetRow = (relY / cellStep).round();

    // Shadow appears as long as targetRow & targetCol fit on the 8x8 board!
    // This allows the finger to comfortably sit below the board when placing on bottom rows!
    final bool isWithinBoardTarget = targetRow >= 0 &&
        targetRow + piece.rows <= BlockBlastGame.boardSize &&
        targetCol >= 0 &&
        targetCol + piece.cols <= BlockBlastGame.boardSize;

    if (isWithinBoardTarget) {
      if (_hoverRow != targetRow || _hoverCol != targetCol) {
        setState(() {
          _hoverRow = targetRow;
          _hoverCol = targetCol;
        });
      }
    } else {
      if (_hoverRow != null || _hoverCol != null) {
        setState(() {
          _hoverRow = null;
          _hoverCol = null;
        });
      }
    }
  }

  void _handleDragEnd(int pieceIndex, BlockShape piece) {
    if (_hoverRow != null && _hoverCol != null) {
      _handlePlacement(pieceIndex, _hoverRow!, _hoverCol!);
    }
    setState(() {
      _draggingPieceIndex = null;
      _hoverRow = null;
      _hoverCol = null;
    });
  }

  void _handlePlacement(int pieceIndex, int row, int col) {
    final piece = widget.game.currentPieces[pieceIndex];
    if (piece == null) return;

    if (widget.game.canPlace(piece, row, col)) {
      final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (gridBox != null) {
        final cellSize = (gridBox.size.width - 10 - 21) / BlockBlastGame.boardSize;
        final cellStep = cellSize + 3.0;

        final cellRects = <Rect>[];
        final cellCenters = <Offset>[];

        for (int r = 0; r < piece.rows; r++) {
          for (int c = 0; c < piece.cols; c++) {
            if (piece.matrix[r][c] == 1) {
              final targetR = row + r;
              final targetC = col + c;
              final left = 5.0 + targetC * cellStep;
              final top = 5.0 + targetR * cellStep;
              final rect = Rect.fromLTWH(
                left,
                top,
                cellSize,
                cellSize,
              );
              cellRects.add(rect);
              cellCenters.add(Offset(left + cellSize / 2, top + cellSize / 2));
              _recentlyPlacedCells.add('$targetR-$targetC');
            }
          }
        }

        final targetScorePos = _getTargetScorePos();
        _particleManager.triggerPlacementSplash(
          cellRects: cellRects,
          cellCenters: cellCenters,
          color: piece.color,
          points: piece.blockCount * 10,
          targetScorePos: targetScorePos,
          onScoreReached: () {
            _scoreBounceAnimController.forward(from: 0.0);
          },
        );

        Future.delayed(const Duration(milliseconds: 280), () {
          if (mounted) {
            setState(() {
              _recentlyPlacedCells.clear();
            });
          }
        });
      }

      widget.game.placePiece(pieceIndex, row, col);
      HapticFeedback.mediumImpact();
      setState(() {
        _selectedPieceIndex = null;
        _draggingPieceIndex = null;
        _hoverRow = null;
        _hoverCol = null;
      });
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _onMascotSegmentTapped(int r, int c, Offset cellCenter) {
    final m = widget.game.currentMascot;
    if (m == null) return;
    final pts = widget.game.interactMascot(r, c);
    if (pts != null) {
      HapticFeedback.heavyImpact();
      _particleManager.triggerCameoCelebration(
        cellCenter,
        '+$pts ${m.name}! ${m.emoji}',
      );
      final targetScorePos = _getTargetScorePos();
      _particleManager.flyingBadges.add(
        FlyingScoreBadge(
          text: '+$pts',
          startPos: cellCenter,
          targetPos: targetScorePos,
          color: const Color(0xFF84CC16),
          onArrival: () {
            _scoreBounceAnimController.forward(from: 0.0);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    // Responsive board size: Fits both width and height, leaving ample room for tips & tray
    final maxBoardW = (screenW - 44).clamp(240.0, 340.0);
    // Vertical budget: screenH - header (66) - exp (3) - tips (44) - tray (86) - safe padding (75)
    final maxBoardH = (screenH - 274).clamp(230.0, 340.0);
    final rawBoardSize = min(maxBoardW, maxBoardH);

    // Integer cellPx guarantees zero subpixel rounding drift
    final cellPx = ((rawBoardSize - 10 - 21) / BlockBlastGame.boardSize).floorToDouble();
    final boardInnerSize = cellPx * BlockBlastGame.boardSize + 21; // 8 cells + 7 gaps of 3px
    final boardTotalSize = boardInnerSize + 10; // + 5px padding each side

    return BlastParticleOverlay(
      manager: _particleManager,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.85),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header (Level, Mode Toggle, Score, High Score, Actions)
              _buildHeader(game),

              // 2. EXP Bar
              _buildExpBar(game),

              // 3. Compact Combo Toast (Only when combo is active)
              _buildComboToast(game),

              // 4. 8x8 Board Container with Micro-Screen Shake on Blast!
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: SizedBox(
                  width: boardTotalSize,
                  height: boardTotalSize,
                  child: AnimatedBuilder(
                    animation: _particleManager,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: _particleManager.shakeOffset,
                        child: child,
                      );
                    },
                    child: _buildBoard(game, boardTotalSize, cellPx),
                  ),
                ),
              ),

              const SizedBox(height: 3),

              // 5. Tips, Tricks & Fun Facts Card (Separated cleanly, never covers board!)
              _buildFunFactBar(game),

              const SizedBox(height: 3),

              // 6. Piece Tray (1:1 Drag Scale feedback)
              Container(
                height: 86,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: _buildPieceTray(game, cellPx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BlockBlastGame game) {
    final isUrgentTime = game.isTimeAttackMode && game.remainingSeconds <= 15;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      'LV.${game.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Mode Indicator & Switcher (Santai vs Tantangan Waktu)
              InkWell(
                onTap: () => game.toggleTimeMode(),
                borderRadius: BorderRadius.circular(9),
                child: ScaleTransition(
                  scale: isUrgentTime ? _timerPulseAnim : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: game.isTimeAttackMode
                          ? (isUrgentTime
                              ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                              : const Color(0xFF0F172A))
                          : const Color(0xFF10B981).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: game.isTimeAttackMode
                            ? (isUrgentTime ? const Color(0xFFEF4444) : const Color(0xFF38BDF8).withValues(alpha: 0.4))
                            : const Color(0xFF10B981).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          game.isTimeAttackMode ? Icons.timer_outlined : Icons.spa_rounded,
                          color: game.isTimeAttackMode
                              ? (isUrgentTime ? const Color(0xFFEF4444) : const Color(0xFF38BDF8))
                              : const Color(0xFF34D399),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          game.isTimeAttackMode ? '${game.remainingSeconds}s' : 'Santai',
                          style: TextStyle(
                            color: game.isTimeAttackMode
                                ? (isUrgentTime ? const Color(0xFFEF4444) : Colors.white)
                                : const Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions: Restart, Minimize, Close
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 18),
                    tooltip: 'Ulang Permainan',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _selectedPieceIndex = null;
                        _draggingPieceIndex = null;
                        _hoverRow = null;
                        _hoverCol = null;
                        _lastHandledBlastTimestamp = null;
                        _lastCelebratedLevel = 1;
                        game.initGame();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Color(0xFF38BDF8), size: 20),
                    tooltip: 'Minimize ke Bubble Chat',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onMinimize,
                  ),
                  if (widget.onClose != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                      tooltip: 'Tutup',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onClose,
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Score & High Score Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current Score with Flying Points Bounce
              Row(
                children: [
                  ScaleTransition(
                    scale: _scoreBounceAnim,
                    child: Container(
                      key: _scoreBadgeKey,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on, color: Color(0xFF10B981), size: 15),
                          const SizedBox(width: 3),
                          Text(
                            '${game.score}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    game.levelTitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // High Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 13),
                    const SizedBox(width: 3),
                    Text(
                      'BEST: ${game.highScore}',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpBar(BlockBlastGame game) {
    return Container(
      height: 3,
      width: double.infinity,
      color: const Color(0xFF0F172A),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: game.expProgress,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComboToast(BlockBlastGame game) {
    if (game.lastBlast == null) return const SizedBox(height: 2);

    final blast = game.lastBlast!;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: ScaleTransition(
        scale: _comboScaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${blast.comboMessage} +${blast.pointsEarned} PTS (+${blast.bonusSeconds}s ⏱️)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunFactBar(BlockBlastGame game) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFBBF24), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                game.currentFunFact,
                key: ValueKey(game.currentFunFact),
                maxLines: 2, // Multi-line readable text! Never cut off!
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 10.0,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(BlockBlastGame game, double totalSize, double cellPx) {
    final activePieceIndex = _draggingPieceIndex ?? _selectedPieceIndex;
    final activePiece = activePieceIndex != null ? game.currentPieces[activePieceIndex] : null;

    return Container(
      key: _gridKey,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 8x8 Grid Tiles (Rigid Column of Rows: Zero overflow, zero scroll drift!)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(BlockBlastGame.boardSize, (r) {
              return Padding(
                padding: EdgeInsets.only(bottom: r < BlockBlastGame.boardSize - 1 ? 3.0 : 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(BlockBlastGame.boardSize, (c) {
                    final cellColor = game.board[r][c];
                    final isRecentlyPlaced = _recentlyPlacedCells.contains('$r-$c');
                    final bonusTile = game.bonusCells['$r-$c'];

                    // Check if cell is occupied by slithering mascot
                    final mascot = game.currentMascot;
                    final isMascotSegment = mascot != null && mascot.occupies(r, c) && cellColor == null;
                    final mascotSegIndex = isMascotSegment ? mascot.indexOf(r, c) : -1;

                    // Ghost shadow check: ONLY visible when placement is 100% valid!
                    bool isGhost = false;
                    Color? ghostColor;

                    if (activePiece != null && _hoverRow != null && _hoverCol != null) {
                      final canPlaceCurrent = game.canPlace(activePiece, _hoverRow!, _hoverCol!);
                      if (canPlaceCurrent) {
                        final offsetR = r - _hoverRow!;
                        final offsetC = c - _hoverCol!;
                        if (offsetR >= 0 &&
                            offsetR < activePiece.rows &&
                            offsetC >= 0 &&
                            offsetC < activePiece.cols) {
                          if (activePiece.matrix[offsetR][offsetC] == 1) {
                            isGhost = true;
                            ghostColor = activePiece.color;
                          }
                        }
                      }
                    }

                    return Padding(
                      padding: EdgeInsets.only(right: c < BlockBlastGame.boardSize - 1 ? 3.0 : 0.0),
                      child: SizedBox(
                        width: cellPx,
                        height: cellPx,
                        child: InkWell(
                          onTap: () {
                            if (isMascotSegment) {
                              final cellCenter = Offset(5.0 + c * (cellPx + 3.0) + cellPx / 2, 5.0 + r * (cellPx + 3.0) + cellPx / 2);
                              _onMascotSegmentTapped(r, c, cellCenter);
                            } else if (_selectedPieceIndex != null && activePiece != null) {
                              _handlePlacement(_selectedPieceIndex!, r, c);
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: _buildCellTile(
                            cellColor: cellColor,
                            isGhost: isGhost,
                            ghostColor: ghostColor,
                            isRecentlyPlaced: isRecentlyPlaced,
                            bonusTile: bonusTile,
                            mascot: isMascotSegment ? mascot : null,
                            mascotSegIndex: mascotSegIndex,
                            cellSize: cellPx,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),

          // Game Over Overlay with Revive / Second Chance!
          if (game.isGameOver)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '💥 GAME OVER 💥',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          game.isTimeAttackMode && game.remainingSeconds <= 0
                              ? '⏰ WAKTU SHIFT HABIS!'
                              : '🚫 TIDAK ADA KOTAK MUAT!',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Skor Akhir: ${game.score}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Pangkat: ${game.levelTitle} (Lv. ${game.level})',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Second Chance (Revive) Button if available!
                        if (game.canRevive) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            icon: const Icon(Icons.bolt, size: 18),
                            label: const Text(
                              '⚡ Kesempatan Kedua (Revive)',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedPieceIndex = null;
                                _draggingPieceIndex = null;
                                _hoverRow = null;
                                _hoverCol = null;
                                game.reviveGame();
                              });
                              HapticFeedback.heavyImpact();
                              SystemSound.play(SystemSoundType.click);
                            },
                          ),
                          const SizedBox(height: 8),
                        ],

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                          ),
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text(
                            'Main Lagi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedPieceIndex = null;
                              _draggingPieceIndex = null;
                              _hoverRow = null;
                              _hoverCol = null;
                              _lastHandledBlastTimestamp = null;
                              _lastCelebratedLevel = 1;
                              game.initGame();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCellTile({
    required Color? cellColor,
    required bool isGhost,
    required Color? ghostColor,
    required bool isRecentlyPlaced,
    required BonusTile? bonusTile,
    required SlitheringMascot? mascot,
    required int mascotSegIndex,
    required double cellSize,
  }) {
    Color tileBg = const Color(0xFF0F172A);
    Color borderColor = Colors.white.withValues(alpha: _outlineNeonAnim.value);
    BoxBorder? tileBorder;
    Gradient? tileGradient;
    Widget? contentWidget;

    if (cellColor != null) {
      tileGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cellColor.withValues(alpha: 0.98),
          cellColor,
          cellColor.withValues(alpha: 0.80),
        ],
      );
      tileBorder = Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.50), width: 1.5),
        left: BorderSide(color: Colors.white.withValues(alpha: 0.38), width: 1.5),
        bottom: BorderSide(color: Colors.black.withValues(alpha: 0.40), width: 1.5),
        right: BorderSide(color: Colors.black.withValues(alpha: 0.28), width: 1.5),
      );
      final groceryEmoji = BlockShape.getEmojiForColor(cellColor);

      if (bonusTile != null) {
        contentWidget = Stack(
          alignment: Alignment.center,
          children: [
            Text(groceryEmoji, style: TextStyle(fontSize: cellSize * 0.48)),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(bonusTile.icon, color: Colors.amber, size: 10),
            ),
          ],
        );
      } else {
        contentWidget = Text(
          groceryEmoji,
          style: TextStyle(fontSize: cellSize * 0.52),
        );
      }
    } else if (isGhost && ghostColor != null) {
      tileBg = ghostColor.withValues(alpha: 0.40);
      borderColor = ghostColor.withValues(alpha: 0.90);
      final groceryEmoji = BlockShape.getEmojiForColor(ghostColor);
      contentWidget = Text(
        groceryEmoji,
        style: TextStyle(fontSize: cellSize * 0.46),
      );
    } else if (mascot != null) {
      // 🐛 / 🐍 SLITHERING MASCOT MULTI-SEGMENT CRAWLING LIVE!
      tileBg = const Color(0xFF84CC16).withValues(alpha: 0.18);
      borderColor = const Color(0xFF84CC16);

      MascotPart part = MascotPart.body;
      if (mascotSegIndex == 0) {
        part = MascotPart.head;
      } else if (mascotSegIndex == mascot.body.length - 1) {
        part = MascotPart.tail;
      }

      contentWidget = PixelMascotWidget(
        skinId: mascot.skinId,
        part: part,
        direction: mascot.direction,
        animTick: mascot.animTick,
        size: cellSize * 0.88,
      );
    } else if (bonusTile != null) {
      tileBg = bonusTile.color.withValues(alpha: 0.12);
      borderColor = bonusTile.color.withValues(alpha: 0.55);
      contentWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(bonusTile.icon, color: bonusTile.color, size: 13),
          Text(
            '+${bonusTile.bonusPoints}',
            style: TextStyle(
              color: bonusTile.color,
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }

    tileBorder ??= Border.all(
      color: borderColor,
      width: (isGhost || mascot != null) ? 1.5 : 1,
    );

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: tileGradient == null ? tileBg : null,
        gradient: tileGradient,
        borderRadius: BorderRadius.circular(5),
        border: tileBorder,
        boxShadow: cellColor != null
            ? [
                BoxShadow(
                  color: cellColor.withValues(alpha: 0.45),
                  blurRadius: 5,
                  offset: const Offset(0, 1.5),
                ),
              ]
            : (mascot != null)
                ? [
                    BoxShadow(
                      color: const Color(0xFF84CC16).withValues(alpha: 0.5),
                      blurRadius: 7,
                    ),
                  ]
                : (isGhost && ghostColor != null)
                    ? [
                        BoxShadow(
                          color: ghostColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
      ),
      child: Center(child: contentWidget),
    );

    if (isRecentlyPlaced) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildPieceTray(BlockBlastGame game, double cellPx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final piece = game.currentPieces[index];
        if (piece == null) {
          return const Expanded(
            child: Center(
              child: SizedBox(
                width: 45,
                height: 45,
              ),
            ),
          );
        }

        final isSelected = _selectedPieceIndex == index;
        final totalPieceW = piece.cols * cellPx + (piece.cols - 1) * 3.0;
        final totalPieceH = piece.rows * cellPx + (piece.rows - 1) * 3.0;

        return Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                if (_selectedPieceIndex == index) {
                  _selectedPieceIndex = null;
                } else {
                  _selectedPieceIndex = index;
                }
              });
              HapticFeedback.selectionClick();
            },
            borderRadius: BorderRadius.circular(12),
            child: Draggable<int>(
              data: index,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              // Lifted feedback matching EXACT 1:1 scale and spacing of board grid!
              feedback: Material(
                color: Colors.transparent,
                child: Transform.translate(
                  offset: Offset(-totalPieceW / 2.0, -totalPieceH - 65.0),
                  child: _buildShapeWidget(piece, isPreview: true, cellSize: cellPx),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.25,
                child: _buildShapeWidget(piece),
              ),
              onDragStarted: () {
                setState(() {
                  _draggingPieceIndex = index;
                  _selectedPieceIndex = index;
                });
                HapticFeedback.lightImpact();
              },
              onDragUpdate: (details) {
                _handleDragUpdate(details.globalPosition, piece, cellPx);
              },
              onDragEnd: (_) {
                _handleDragEnd(index, piece);
              },
              child: AnimatedScale(
                scale: isSelected ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF38BDF8)
                          : Colors.white.withValues(alpha: 0.05),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: _buildShapeWidget(piece),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShapeWidget(BlockShape shape, {bool isPreview = false, double cellSize = 13.5}) {
    final double spacing = isPreview ? 3.0 : 1.5;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(shape.rows, (r) {
        return Padding(
          padding: EdgeInsets.only(bottom: r < shape.rows - 1 ? spacing : 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(shape.cols, (c) {
              final isFilled = shape.matrix[r][c] == 1;
              return Padding(
                padding: EdgeInsets.only(right: c < shape.cols - 1 ? spacing : 0.0),
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: isFilled
                      ? BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              shape.color.withValues(alpha: 0.98),
                              shape.color,
                              shape.color.withValues(alpha: 0.80),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(cellSize > 20 ? 5 : 3),
                          border: Border(
                            top: BorderSide(color: Colors.white.withValues(alpha: 0.50), width: cellSize > 20 ? 1.5 : 1.0),
                            left: BorderSide(color: Colors.white.withValues(alpha: 0.38), width: cellSize > 20 ? 1.5 : 1.0),
                            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.40), width: cellSize > 20 ? 1.5 : 1.0),
                            right: BorderSide(color: Colors.black.withValues(alpha: 0.28), width: cellSize > 20 ? 1.5 : 1.0),
                          ),
                          boxShadow: isPreview
                              ? [
                                  BoxShadow(
                                    color: shape.color.withValues(alpha: 0.65),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        )
                      : const BoxDecoration(color: Colors.transparent),
                  child: isFilled
                      ? Center(
                          child: Text(
                            shape.emoji,
                            style: TextStyle(fontSize: cellSize * (cellSize > 20 ? 0.48 : 0.65)),
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
