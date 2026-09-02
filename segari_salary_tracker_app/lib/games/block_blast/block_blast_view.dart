import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with SingleTickerProviderStateMixin {
  int? _selectedPieceIndex;
  int? _hoverRow;
  int? _hoverCol;

  late AnimationController _comboAnimController;
  late Animation<double> _comboScaleAnim;

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
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGameUpdated);
    _comboAnimController.dispose();
    super.dispose();
  }

  void _onGameUpdated() {
    if (widget.game.lastBlast != null) {
      _comboAnimController.forward(from: 0.0);
      HapticFeedback.mediumImpact();
    }
    setState(() {});
  }

  void _handleCellTap(int row, int col) {
    if (_selectedPieceIndex == null) return;
    final piece = widget.game.currentPieces[_selectedPieceIndex!];
    if (piece == null) return;

    if (widget.game.canPlace(piece, row, col)) {
      widget.game.placePiece(_selectedPieceIndex!, row, col);
      HapticFeedback.lightImpact();
      setState(() {
        _selectedPieceIndex = null;
        _hoverRow = null;
        _hoverCol = null;
      });
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balok tidak muat di posisi tersebut!'),
          duration: Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // 1. Game Header
            _buildHeader(game),

            // 2. Combo Banner
            _buildComboBanner(game),

            const SizedBox(height: 6),

            // 3. 8x8 Board
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildBoard(game),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 4. Instructions / Status
            Text(
              _selectedPieceIndex != null
                  ? '👇 Ketuk kotak di papan untuk menaruh balok'
                  : 'Pilih balok di bawah, lalu pasang di papan!',
              style: TextStyle(
                color: _selectedPieceIndex != null
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFF94A3B8),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // 5. Piece Tray (3 Pieces)
            Container(
              height: 105,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: _buildPieceTray(game),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BlockBlastGame game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score & High Score
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${game.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'BEST: ${game.highScore}',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Actions: Restart, Minimize, Close
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 20),
                tooltip: 'Ulang Permainan',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedPieceIndex = null;
                    game.initGame();
                  });
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.remove, color: Color(0xFF38BDF8), size: 22),
                tooltip: 'Minimize ke Bubble Chat',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onMinimize,
              ),
              if (widget.onClose != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
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
    );
  }

  Widget _buildComboBanner(BlockBlastGame game) {
    if (game.lastBlast == null) return const SizedBox(height: 24);

    return ScaleTransition(
      scale: _comboScaleAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${game.lastBlast!.comboMessage} +${game.lastBlast!.pointsEarned}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(BlockBlastGame game) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // 8x8 Grid Tiles
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

              // Check if cell is in hover preview
              bool isHovered = false;
              Color? hoverColor;
              if (_selectedPieceIndex != null &&
                  _hoverRow != null &&
                  _hoverCol != null) {
                final piece = game.currentPieces[_selectedPieceIndex!];
                if (piece != null) {
                  final offsetR = r - _hoverRow!;
                  final offsetC = c - _hoverCol!;
                  if (offsetR >= 0 &&
                      offsetR < piece.rows &&
                      offsetC >= 0 &&
                      offsetC < piece.cols) {
                    if (piece.matrix[offsetR][offsetC] == 1) {
                      isHovered = true;
                      hoverColor = piece.color;
                    }
                  }
                }
              }

              return InkWell(
                onTap: () => _handleCellTap(r, c),
                onHover: (hovering) {
                  if (_selectedPieceIndex != null) {
                    setState(() {
                      if (hovering) {
                        _hoverRow = r;
                        _hoverCol = c;
                      } else {
                        _hoverRow = null;
                        _hoverCol = null;
                      }
                    });
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (details) {
                    final piece = game.currentPieces[details.data];
                    return piece != null && game.canPlace(piece, r, c);
                  },
                  onAcceptWithDetails: (details) {
                    game.placePiece(details.data, r, c);
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedPieceIndex = null;
                      _hoverRow = null;
                      _hoverCol = null;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    final bool isCandidate = candidateData.isNotEmpty;

                    Color tileColor = const Color(0xFF0F172A);
                    if (cellColor != null) {
                      tileColor = cellColor;
                    } else if (isCandidate && candidateData.first != null) {
                      final candidatePiece = game.currentPieces[candidateData.first!];
                      if (candidatePiece != null) {
                        tileColor = candidatePiece.color.withValues(alpha: 0.6);
                      }
                    } else if (isHovered && hoverColor != null) {
                      tileColor = hoverColor.withValues(alpha: 0.4);
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: cellColor != null
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                        boxShadow: cellColor != null
                            ? [
                                BoxShadow(
                                  color: cellColor.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: cellColor != null
                          ? Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              );
            },
          ),

          // Game Over Overlay
          if (game.isGameOver)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '💥 GAME OVER 💥',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Skor Akhir: ${game.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (game.score >= game.highScore && game.score > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '🎉 REKOR SKOR BARU! 🎉',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      icon: const Icon(Icons.replay, size: 18),
                      label: const Text(
                        'Main Lagi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedPieceIndex = null;
                          game.initGame();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.1,
                  child: _buildShapeWidget(piece, isPreview: true),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildShapeWidget(piece),
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
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
                ),
                child: Center(
                  child: _buildShapeWidget(piece),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShapeWidget(BlockShape shape, {bool isPreview = false}) {
    const double cellSize = 16.0;

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
                                color: shape.color.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    )
                  : const BoxDecoration(color: Colors.transparent),
            );
          }),
        );
      }),
    );
  }
}
