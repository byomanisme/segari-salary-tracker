import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  late AnimationController _bonusPulseController;
  late Animation<double> _bonusPulseAnim;

  @override
  void initState() {
    super.initState();
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

    _bonusPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bonusPulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _bonusPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGameUpdated);
    _comboAnimController.dispose();
    _scoreBounceAnimController.dispose();
    _timerPulseController.dispose();
    _bonusPulseController.dispose();
    _particleManager.dispose();
    super.dispose();
  }

  void _onGameUpdated() {
    final blast = widget.game.lastBlast;
    // FIX LOOPING: Trigger animation EXACTLY ONCE per blast timestamp!
    if (blast != null && blast.timestamp != _lastHandledBlastTimestamp) {
      _lastHandledBlastTimestamp = blast.timestamp;
      _comboAnimController.forward(from: 0.0);
      HapticFeedback.heavyImpact();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerParticlesForBlast(blast);
      });
    }

    if (widget.game.hasLevelUp) {
      HapticFeedback.vibrate();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
        if (gridBox != null) {
          final size = gridBox.size;
          _particleManager.triggerLevelUpAt(Offset(size.width / 2, size.height / 2), widget.game.level);
        }
      });
    }

    setState(() {});
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

    final RenderBox? scoreBox = _scoreBadgeKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox = context.findRenderObject() as RenderBox?;
    Offset targetScorePos = const Offset(90, 45);
    if (scoreBox != null && overlayBox != null) {
      final globalPos = scoreBox.localToGlobal(Offset.zero);
      final localPos = overlayBox.globalToLocal(globalPos);
      targetScorePos = Offset(
        localPos.dx + scoreBox.size.width / 2,
        localPos.dy + scoreBox.size.height / 2,
      );
    }

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

  void _handlePlacement(int pieceIndex, int row, int col) {
    final piece = widget.game.currentPieces[pieceIndex];
    if (piece == null) return;

    if (widget.game.canPlace(piece, row, col)) {
      final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (gridBox != null) {
        final size = gridBox.size;
        final cellW = size.width / BlockBlastGame.boardSize;
        final cellH = size.height / BlockBlastGame.boardSize;
        final centers = <Offset>[];

        for (int r = 0; r < piece.rows; r++) {
          for (int c = 0; c < piece.cols; c++) {
            if (piece.matrix[r][c] == 1) {
              final targetR = row + r;
              final targetC = col + c;
              centers.add(Offset(targetC * cellW + cellW / 2, targetR * cellH + cellH / 2));
              _recentlyPlacedCells.add('$targetR-$targetC');
            }
          }
        }

        _particleManager.triggerPlacementEffectAt(centers, piece.color);

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

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

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
              color: Colors.black.withValues(alpha: 0.8),
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
              // 1. Header (Level, Timer, Score, High Score, Actions)
              _buildHeader(game),

              // 2. EXP Bar
              _buildExpBar(game),

              // 3. Compact Combo Notification Toast (NO LAYOUT PUSH)
              _buildComboToast(game),

              // 4. 8x8 Board with Mystery Bonus Cells & Corrected Ghost Preview
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: _buildBoard(game),
                    ),
                  ),
                ),
              ),

              // 5. Sleek Compact Instruction
              _buildInstructionText(),

              // 6. Piece Tray (Real block at finger touch, no weird offset!)
              Container(
                height: 105,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: _buildPieceTray(game),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BlockBlastGame game) {
    final isUrgentTime = game.remainingSeconds <= 15;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'LV.${game.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Shift Countdown Timer
              ScaleTransition(
                scale: isUrgentTime ? _timerPulseAnim : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUrgentTime
                        ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUrgentTime ? const Color(0xFFEF4444) : const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: isUrgentTime ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.remainingSeconds}s',
                        style: TextStyle(
                          color: isUrgentTime ? const Color(0xFFEF4444) : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions: Restart, Minimize, Close
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 19),
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
                        game.initGame();
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Color(0xFF38BDF8), size: 21),
                    tooltip: 'Minimize ke Bubble Chat',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onMinimize,
                  ),
                  if (widget.onClose != null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 19),
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

          const SizedBox(height: 5),

          // Score & High Score Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current Score with Flying Points Impact Bounce
              Row(
                children: [
                  ScaleTransition(
                    scale: _scoreBounceAnim,
                    child: Container(
                      key: _scoreBadgeKey,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${game.score}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
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
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // High Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
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
                        fontSize: 10.5,
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

  /// Compact Toast that never covers board blocks
  Widget _buildComboToast(BlockBlastGame game) {
    if (game.lastBlast == null) return const SizedBox(height: 6);

    final blast = game.lastBlast!;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: ScaleTransition(
        scale: _comboScaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${blast.comboMessage} +${blast.pointsEarned} PTS (+${blast.bonusSeconds}s ⏱️)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionText() {
    String text = '🎁 Kumpulkan ikon bonus di kotak untuk poin ekstra!';
    Color textColor = const Color(0xFFFBBF24);

    if (_draggingPieceIndex != null) {
      text = '🎯 Letakkan balok tepat di bayangan kotak!';
      textColor = const Color(0xFF10B981);
    } else if (_selectedPieceIndex != null) {
      text = '👇 Ketuk kotak di papan untuk meletakkan balok';
      textColor = const Color(0xFF38BDF8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBoard(BlockBlastGame game) {
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
        children: [
          // 8x8 Grid Tiles with Corrected DragTarget
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: BlockBlastGame.boardSize * BlockBlastGame.boardSize,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: BlockBlastGame.boardSize,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemBuilder: (context, index) {
              final r = index ~/ BlockBlastGame.boardSize;
              final c = index % BlockBlastGame.boardSize;
              final cellColor = game.board[r][c];
              final isRecentlyPlaced = _recentlyPlacedCells.contains('$r-$c');
              final bonusTile = game.bonusCells['$r-$c'];

              // Check if cell is in ghost preview
              bool isGhost = false;
              bool isValidGhost = false;
              Color? ghostColor;

              if (activePiece != null && _hoverRow != null && _hoverCol != null) {
                final offsetR = r - _hoverRow!;
                final offsetC = c - _hoverCol!;
                if (offsetR >= 0 &&
                    offsetR < activePiece.rows &&
                    offsetC >= 0 &&
                    offsetC < activePiece.cols) {
                  if (activePiece.matrix[offsetR][offsetC] == 1) {
                    isGhost = true;
                    isValidGhost = game.canPlace(activePiece, _hoverRow!, _hoverCol!);
                    ghostColor = activePiece.color;
                  }
                }
              }

              return DragTarget<int>(
                onWillAcceptWithDetails: (details) {
                  if (activePiece == null) return false;
                  // REVERSE FIX: Finger touches cell (r, c).
                  // Position the ghost shadow target ABOVE the finger so thumb does not cover board!
                  final targetRow = (r - 1).clamp(0, BlockBlastGame.boardSize - activePiece.rows);
                  final targetCol = (c - (activePiece.cols ~/ 2)).clamp(0, BlockBlastGame.boardSize - activePiece.cols);

                  setState(() {
                    _hoverRow = targetRow;
                    _hoverCol = targetCol;
                    _draggingPieceIndex = details.data;
                  });
                  return true;
                },
                onLeave: (_) {},
                onAcceptWithDetails: (details) {
                  final piece = game.currentPieces[details.data];
                  if (piece != null) {
                    final targetRow = (r - 1).clamp(0, BlockBlastGame.boardSize - piece.rows);
                    final targetCol = (c - (piece.cols ~/ 2)).clamp(0, BlockBlastGame.boardSize - piece.cols);
                    _handlePlacement(details.data, targetRow, targetCol);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return InkWell(
                    onTap: () {
                      if (_selectedPieceIndex != null && activePiece != null) {
                        _handlePlacement(_selectedPieceIndex!, r, c);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: _buildCellTile(
                      cellColor: cellColor,
                      isGhost: isGhost,
                      isValidGhost: isValidGhost,
                      ghostColor: ghostColor,
                      isRecentlyPlaced: isRecentlyPlaced,
                      bonusTile: bonusTile,
                    ),
                  );
                },
              );
            },
          ),

          // Game Over Overlay
          if (game.isGameOver)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
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
                        game.remainingSeconds <= 0 ? '⏰ WAKTU SHIFT HABIS!' : '🚫 TIDAK ADA KOTAK MUAT!',
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
                            game.initGame();
                          });
                        },
                      ),
                    ],
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
    required bool isValidGhost,
    required Color? ghostColor,
    required bool isRecentlyPlaced,
    required BonusTile? bonusTile,
  }) {
    Color tileBg = const Color(0xFF0F172A);
    Color borderColor = Colors.white.withValues(alpha: 0.05);
    Widget? iconWidget;

    if (cellColor != null) {
      tileBg = cellColor;
      borderColor = Colors.white.withValues(alpha: 0.3);
      final iconData = BlockShape.getIconForColor(cellColor);

      // If cell also has a captured Mystery Bonus, show a shining star badge!
      if (bonusTile != null) {
        iconWidget = Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              iconData,
              color: Colors.white.withValues(alpha: 0.75),
              size: 13,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: ScaleTransition(
                scale: _bonusPulseAnim,
                child: Icon(
                  bonusTile.icon,
                  color: Colors.amber,
                  size: 10,
                ),
              ),
            ),
          ],
        );
      } else {
        iconWidget = Icon(
          iconData,
          color: Colors.white.withValues(alpha: 0.9),
          size: 14,
        );
      }
    } else if (isGhost) {
      if (isValidGhost && ghostColor != null) {
        tileBg = ghostColor.withValues(alpha: 0.45);
        borderColor = ghostColor.withValues(alpha: 0.9);
        final iconData = BlockShape.getIconForColor(ghostColor);
        iconWidget = Icon(
          iconData,
          color: Colors.white.withValues(alpha: 0.7),
          size: 13,
        );
      } else {
        tileBg = const Color(0xFFEF4444).withValues(alpha: 0.35);
        borderColor = const Color(0xFFEF4444);
        iconWidget = const Icon(
          Icons.close,
          color: Colors.white70,
          size: 12,
        );
      }
    } else if (bonusTile != null) {
      // Mystery Bonus Tile on an empty cell!
      tileBg = bonusTile.color.withValues(alpha: 0.12);
      borderColor = bonusTile.color.withValues(alpha: 0.45);
      iconWidget = ScaleTransition(
        scale: _bonusPulseAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              bonusTile.icon,
              color: bonusTile.color,
              size: 14,
            ),
            Text(
              '+${bonusTile.bonusPoints}',
              style: TextStyle(
                color: bonusTile.color,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: borderColor,
          width: isGhost ? 1.5 : 1,
        ),
        boxShadow: cellColor != null
            ? [
                BoxShadow(
                  color: cellColor.withValues(alpha: 0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ]
            : (bonusTile != null && cellColor == null)
                ? [
                    BoxShadow(
                      color: bonusTile.color.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ]
                : (isGhost && isValidGhost && ghostColor != null)
                    ? [
                        BoxShadow(
                          color: ghostColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
      ),
      child: Center(child: iconWidget),
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

  Widget _buildPieceTray(BlockBlastGame game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final piece = game.currentPieces[index];
        if (piece == null) {
          return const Expanded(
            child: Center(
              child: SizedBox(
                width: 50,
                height: 50,
              ),
            ),
          );
        }

        final isSelected = _selectedPieceIndex == index;

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
              // REAL BLOCK AT FINGER TOUCH: NO WEIRD -65PX OFFSET!
              feedback: Material(
                color: Colors.transparent,
                child: _buildShapeWidget(piece, isPreview: true, cellSize: 22.0),
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
              onDragEnd: (_) {
                setState(() {
                  _draggingPieceIndex = null;
                  _hoverRow = null;
                  _hoverCol = null;
                });
              },
              child: AnimatedScale(
                scale: isSelected ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.all(4),
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
                              blurRadius: 10,
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

  Widget _buildShapeWidget(BlockShape shape, {bool isPreview = false, double cellSize = 15.0}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(shape.rows, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(shape.cols, (c) {
            final isFilled = shape.matrix[r][c] == 1;
            return Container(
              width: cellSize,
              height: cellSize,
              margin: const EdgeInsets.all(1),
              decoration: isFilled
                  ? BoxDecoration(
                      color: shape.color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isPreview
                          ? [
                              BoxShadow(
                                color: shape.color.withValues(alpha: 0.55),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    )
                  : const BoxDecoration(color: Colors.transparent),
              child: isFilled
                  ? Center(
                      child: Icon(
                        shape.icon,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: cellSize * 0.6,
                      ),
                    )
                  : null,
            );
          }),
        );
      }),
    );
  }
}
