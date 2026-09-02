import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../games/block_blast/block_blast_game.dart';
import '../games/block_blast/block_blast_view.dart';

class FloatingGameBubble extends StatefulWidget {
  final bool isVisible;

  const FloatingGameBubble({
    super.key,
    this.isVisible = true,
  });

  @override
  State<FloatingGameBubble> createState() => _FloatingGameBubbleState();
}

class _FloatingGameBubbleState extends State<FloatingGameBubble>
    with SingleTickerProviderStateMixin {
  // Persistent game state so minimizing preserves board & score
  final BlockBlastGame _game = BlockBlastGame();

  Offset? _position;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _game.dispose();
    super.dispose();
  }

  void _openGameDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Block Blast',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 380,
                ),
                child: BlockBlastView(
                  game: _game,
                  onMinimize: () => Navigator.pop(context),
                  onClose: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    const double bubbleSize = 56.0;

    // Default position: bottom right, above bottom nav
    _position ??= Offset(
      screenSize.width - bubbleSize - 16,
      screenSize.height - bubbleSize - 120,
    );

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newX = (_position!.dx + details.delta.dx).clamp(
              8.0,
              screenSize.width - bubbleSize - 8.0,
            );
            final newY = (_position!.dy + details.delta.dy).clamp(
              40.0,
              screenSize.height - bubbleSize - 80.0,
            );
            _position = Offset(newX, newY);
          });
        },
        onPanEnd: (details) {
          // Snap bubble to nearest left or right edge
          final midX = screenSize.width / 2;
          final targetX = _position!.dx < midX
              ? 12.0
              : screenSize.width - bubbleSize - 12.0;

          setState(() {
            _position = Offset(targetX, _position!.dy);
          });
        },
        onTap: _openGameDialog,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: bubbleSize,
                height: bubbleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0284C7), // Segari Sky Blue
                      Color(0xFF10B981), // Segari Emerald
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gamepad / Block Icon
                    const Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.white,
                      size: 28,
                    ),

                    // Tiny Segari Leaf / Game Badge
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
