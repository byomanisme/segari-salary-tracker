import 'dart:math';
import 'package:flutter/material.dart';

class BlastParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double opacity;
  double life; // 0.0 to 1.0

  BlastParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
    this.life = 1.0,
  });

  bool update(double dt) {
    x += vx * dt * 60;
    y += vy * dt * 60;
    vy += 0.15 * dt * 60; // slight gravity
    life -= 1.8 * dt;
    opacity = life.clamp(0.0, 1.0);
    return life > 0;
  }
}

class ShockwaveRing {
  double x;
  double y;
  double radius;
  double maxRadius;
  Color color;
  double life; // 0.0 to 1.0

  ShockwaveRing({
    required this.x,
    required this.y,
    required this.radius,
    required this.maxRadius,
    required this.color,
    this.life = 1.0,
  });

  bool update(double dt) {
    radius += (maxRadius - radius) * 8 * dt;
    life -= 3.0 * dt;
    return life > 0;
  }
}

/// Efek splash outline yang persis mengikuti bentuk balok yang baru dipasang
class ShapeOutlineSplash {
  final List<Rect> cellRects;
  final Color color;
  double life; // 1.0 to 0.0

  ShapeOutlineSplash({
    required this.cellRects,
    required this.color,
    this.life = 1.0,
  });

  bool update(double dt) {
    life -= 3.2 * dt; // disappears in ~300ms
    return life > 0;
  }
}

class FloatingScoreText {
  String text;
  double x;
  double y;
  Color color;
  double scale;
  double life;

  FloatingScoreText({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    this.scale = 1.0,
    this.life = 1.0,
  });

  bool update(double dt) {
    y -= 65 * dt; // floats quickly upwards
    life -= 2.2 * dt; // vanishes smoothly within ~0.45s
    return life > 0;
  }
}

/// Animasi Poin yang melesat dari baris yang meledak ke Total Score di header
class FlyingScoreBadge {
  final String text;
  final Offset startPos;
  final Offset targetPos;
  final Offset controlPoint;
  final Color color;
  final VoidCallback? onArrival;
  double progress; // 0.0 to 1.0

  FlyingScoreBadge({
    required this.text,
    required this.startPos,
    required this.targetPos,
    required this.color,
    this.onArrival,
    this.progress = 0.0,
  }) : controlPoint = Offset(
          (startPos.dx + targetPos.dx) / 2 + (startPos.dx > targetPos.dx ? -35 : 35),
          min(startPos.dy, targetPos.dy) - 55,
        );

  Offset get currentPos {
    final t = progress.clamp(0.0, 1.0);
    // Quadratic Bezier curve
    final p0 = startPos;
    final p1 = controlPoint;
    final p2 = targetPos;
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  bool update(double dt) {
    progress += 1.45 * dt; // ~0.65s journey
    if (progress >= 1.0) {
      onArrival?.call();
      return false; // finished
    }
    return true;
  }
}

class BlastParticleOverlay extends StatefulWidget {
  final Widget child;
  final BlastParticleManager manager;

  const BlastParticleOverlay({
    super.key,
    required this.child,
    required this.manager,
  });

  @override
  State<BlastParticleOverlay> createState() => _BlastParticleOverlayState();
}

class _BlastParticleOverlayState extends State<BlastParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  DateTime _lastTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      final now = DateTime.now();
      final dt = (now.difference(_lastTime).inMilliseconds / 1000.0).clamp(0.001, 0.05);
      _lastTime = now;
      widget.manager.update(dt);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: widget.manager,
              builder: (context, _) {
                return CustomPaint(
                  painter: BlastParticlePainter(
                    particles: widget.manager.particles,
                    shockwaves: widget.manager.shockwaves,
                    outlineSplashes: widget.manager.outlineSplashes,
                    floatingTexts: widget.manager.floatingTexts,
                    flyingBadges: widget.manager.flyingBadges,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class BlastParticleManager extends ChangeNotifier {
  final List<BlastParticle> particles = [];
  final List<ShockwaveRing> shockwaves = [];
  final List<ShapeOutlineSplash> outlineSplashes = [];
  final List<FloatingScoreText> floatingTexts = [];
  final List<FlyingScoreBadge> flyingBadges = [];
  final Random _random = Random();

  /// Animasi ketika meletakkan balok dengan outline splash persis bentuk balok
  void triggerPlacementSplash({
    required List<Rect> cellRects,
    required List<Offset> cellCenters,
    required Color color,
    required int points,
    required Offset targetScorePos,
    VoidCallback? onScoreReached,
  }) {
    // 1. Expanding neon outline splash of the EXACT placed shape!
    outlineSplashes.add(
      ShapeOutlineSplash(
        cellRects: cellRects,
        color: color,
      ),
    );

    // 2. Small burst of sparkle dust at each cell center
    for (final center in cellCenters) {
      for (int i = 0; i < 3; i++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 1.0 + _random.nextDouble() * 2.0;
        particles.add(
          BlastParticle(
            x: center.dx,
            y: center.dy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            size: 2.5,
            color: color,
            life: 0.45,
          ),
        );
      }
    }

    // 3. Placement points directly flying from placed shape center to Total Score!
    if (cellCenters.isNotEmpty && points > 0) {
      double avgX = 0;
      double avgY = 0;
      for (final c in cellCenters) {
        avgX += c.dx;
        avgY += c.dy;
      }
      avgX /= cellCenters.length;
      avgY /= cellCenters.length;

      flyingBadges.add(
        FlyingScoreBadge(
          text: '+$points',
          startPos: Offset(avgX, avgY),
          targetPos: targetScorePos,
          color: color,
          onArrival: onScoreReached,
        ),
      );
    }

    notifyListeners();
  }

  /// Animasi ledakan line blast dan poin bergerak ke Total Skor
  void triggerBlastAt({
    required List<Offset> cellCenters,
    required List<Color> colors,
    required String comboText,
    required int points,
    required Offset targetScorePos,
    VoidCallback? onScoreReached,
  }) {
    for (int i = 0; i < cellCenters.length; i++) {
      final center = cellCenters[i];
      final color = colors.isNotEmpty ? colors[i % colors.length] : const Color(0xFF10B981);

      shockwaves.add(
        ShockwaveRing(
          x: center.dx,
          y: center.dy,
          radius: 6,
          maxRadius: 36,
          color: color,
        ),
      );

      final count = 7 + _random.nextInt(4);
      for (int k = 0; k < count; k++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 2.2 + _random.nextDouble() * 5.0;
        particles.add(
          BlastParticle(
            x: center.dx,
            y: center.dy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 1.8,
            size: 3.5 + _random.nextDouble() * 3.0,
            color: color,
          ),
        );
      }
    }

    if (cellCenters.isNotEmpty) {
      double avgX = 0;
      double avgY = 0;
      for (final pt in cellCenters) {
        avgX += pt.dx;
        avgY += pt.dy;
      }
      avgX /= cellCenters.length;
      avgY /= cellCenters.length;
      final startCenter = Offset(avgX, avgY);

      flyingBadges.add(
        FlyingScoreBadge(
          text: '+$points',
          startPos: startCenter,
          targetPos: targetScorePos,
          color: const Color(0xFF10B981),
          onArrival: onScoreReached,
        ),
      );
    }

    notifyListeners();
  }

  /// Perayaan interaksi Cameo Ulat/Ular Segari
  void triggerCameoCelebration(Offset center, String message) {
    shockwaves.add(
      ShockwaveRing(
        x: center.dx,
        y: center.dy,
        radius: 8,
        maxRadius: 40,
        color: const Color(0xFF84CC16),
      ),
    );

    for (int i = 0; i < 16; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 1.8 + _random.nextDouble() * 3.5;
      particles.add(
        BlastParticle(
          x: center.dx,
          y: center.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 1.0,
          size: 3.0,
          color: i % 2 == 0 ? const Color(0xFF84CC16) : const Color(0xFFFBBF24),
          life: 0.6,
        ),
      );
    }

    floatingTexts.add(
      FloatingScoreText(
        text: message,
        x: center.dx,
        y: center.dy - 10,
        color: const Color(0xFFFBBF24),
      ),
    );

    notifyListeners();
  }

  /// Animasi Level Up perayaan
  void triggerLevelUpAt(Offset center, int level) {
    shockwaves.add(
      ShockwaveRing(
        x: center.dx,
        y: center.dy,
        radius: 10,
        maxRadius: 100,
        color: const Color(0xFFF59E0B),
      ),
    );

    for (int i = 0; i < 28; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 2.0 + _random.nextDouble() * 6.0;
      particles.add(
        BlastParticle(
          x: center.dx,
          y: center.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 2.0,
          size: 3.5 + _random.nextDouble() * 4.0,
          color: i % 2 == 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        ),
      );
    }

    floatingTexts.add(
      FloatingScoreText(
        text: '⭐ LEVEL UP! LV.$level ⭐',
        x: center.dx,
        y: center.dy - 30,
        color: const Color(0xFFF59E0B),
      ),
    );

    notifyListeners();
  }

  void update(double dt) {
    if (particles.isEmpty &&
        shockwaves.isEmpty &&
        outlineSplashes.isEmpty &&
        floatingTexts.isEmpty &&
        flyingBadges.isEmpty) {
      return;
    }

    for (final badge in flyingBadges) {
      final pos = badge.currentPos;
      particles.add(
        BlastParticle(
          x: pos.dx,
          y: pos.dy,
          vx: (_random.nextDouble() - 0.5) * 1.5,
          vy: (_random.nextDouble() - 0.5) * 1.5,
          size: 2.5,
          color: const Color(0xFFFBBF24),
          life: 0.35,
        ),
      );
    }

    particles.removeWhere((p) => !p.update(dt));
    shockwaves.removeWhere((s) => !s.update(dt));
    outlineSplashes.removeWhere((o) => !o.update(dt));
    floatingTexts.removeWhere((t) => !t.update(dt));
    flyingBadges.removeWhere((b) => !b.update(dt));
    notifyListeners();
  }
}

class BlastParticlePainter extends CustomPainter {
  final List<BlastParticle> particles;
  final List<ShockwaveRing> shockwaves;
  final List<ShapeOutlineSplash> outlineSplashes;
  final List<FloatingScoreText> floatingTexts;
  final List<FlyingScoreBadge> flyingBadges;

  BlastParticlePainter({
    required this.particles,
    required this.shockwaves,
    required this.outlineSplashes,
    required this.floatingTexts,
    required this.flyingBadges,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Shape Outline Splashes (matching exact placed polyomino!)
    for (final splash in outlineSplashes) {
      final alpha = splash.life.clamp(0.0, 1.0);
      final expansion = (1.0 - splash.life) * 10.0;
      final strokePaint = Paint()
        ..color = splash.color.withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * splash.life;

      final glowPaint = Paint()
        ..color = splash.color.withValues(alpha: alpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 * splash.life
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      for (final rect in splash.cellRects) {
        final rrect = RRect.fromRectAndRadius(
          rect.inflate(expansion),
          const Radius.circular(6),
        );
        canvas.drawRRect(rrect, glowPaint);
        canvas.drawRRect(rrect, strokePaint);
      }
    }

    // 2. Draw Shockwave Rings
    for (final s in shockwaves) {
      final ringPaint = Paint()
        ..color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0) * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s.life;
      canvas.drawCircle(Offset(s.x, s.y), s.radius, ringPaint);
    }

    // 3. Draw Particles
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);

      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * 0.45, corePaint);
    }

    // 4. Draw Floating Text (Fades out quickly)
    for (final t in floatingTexts) {
      final textSpan = TextSpan(
        text: t.text,
        style: TextStyle(
          color: t.color.withValues(alpha: t.life.clamp(0.0, 1.0)),
          fontSize: 14.5,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.9),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        t.x - textPainter.width / 2,
        t.y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }

    // 5. Draw Flying Score Badges
    for (final badge in flyingBadges) {
      final pos = badge.currentPos;
      final t = badge.progress.clamp(0.0, 1.0);
      final scale = t < 0.2 ? (t / 0.2) * 1.2 : (t < 0.7 ? 1.2 : 1.2 - (t - 0.7) * 0.6);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.scale(scale);

      final textSpan = TextSpan(
        text: '⚡ ${badge.text}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black87,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeWidth = textPainter.width + 18;
      final badgeHeight = textPainter.height + 10;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: badgeWidth, height: badgeHeight),
        const Radius.circular(16),
      );

      final glowPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(rect, glowPaint);

      final bgPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF10B981)],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, bgPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rect, borderPaint);

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BlastParticlePainter oldDelegate) => true;
}
