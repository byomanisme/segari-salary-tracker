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
    // Quadratic Bezier curve: p(t) = (1-t)^2 * p0 + 2(1-t)t * p1 + t^2 * p2
    final p0 = startPos;
    final p1 = controlPoint;
    final p2 = targetPos;
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  bool update(double dt) {
    progress += 1.35 * dt; // ~0.7s journey
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
  final List<FloatingScoreText> floatingTexts = [];
  final List<FlyingScoreBadge> flyingBadges = [];
  final Random _random = Random();

  /// Animasi ketika meletakkan balok (Placement Impact Animation)
  void triggerPlacementEffectAt(List<Offset> cellCenters, Color color) {
    for (final center in cellCenters) {
      shockwaves.add(
        ShockwaveRing(
          x: center.dx,
          y: center.dy,
          radius: 4,
          maxRadius: 28,
          color: color,
        ),
      );

      for (int i = 0; i < 5; i++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 1.2 + _random.nextDouble() * 2.5;
        particles.add(
          BlastParticle(
            x: center.dx,
            y: center.dy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            size: 2.5 + _random.nextDouble() * 2.0,
            color: color,
          ),
        );
      }
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
    // 1. Spawn particles and shockwaves from each cleared cell
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

      final count = 8 + _random.nextInt(5);
      for (int k = 0; k < count; k++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 2.5 + _random.nextDouble() * 5.5;
        particles.add(
          BlastParticle(
            x: center.dx,
            y: center.dy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 1.8,
            size: 3.5 + _random.nextDouble() * 3.5,
            color: color,
          ),
        );
      }
    }

    // 2. Spawn floating banner & flying score badge from the blast center to total score
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

      floatingTexts.add(
        FloatingScoreText(
          text: comboText,
          x: avgX,
          y: avgY,
          color: const Color(0xFFFBBF24),
        ),
      );

      // Flying score badge directly traveling to total score!
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
        floatingTexts.isEmpty &&
        flyingBadges.isEmpty) {
      return;
    }

    // Add trailing sparkle dust behind each flying score badge
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
          life: 0.4,
        ),
      );
    }

    particles.removeWhere((p) => !p.update(dt));
    shockwaves.removeWhere((s) => !s.update(dt));
    floatingTexts.removeWhere((t) => !t.update(dt));
    flyingBadges.removeWhere((b) => !b.update(dt));
    notifyListeners();
  }
}

class BlastParticlePainter extends CustomPainter {
  final List<BlastParticle> particles;
  final List<ShockwaveRing> shockwaves;
  final List<FloatingScoreText> floatingTexts;
  final List<FlyingScoreBadge> flyingBadges;

  BlastParticlePainter({
    required this.particles,
    required this.shockwaves,
    required this.floatingTexts,
    required this.flyingBadges,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Shockwave Rings
    for (final s in shockwaves) {
      final ringPaint = Paint()
        ..color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0) * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s.life;
      canvas.drawCircle(Offset(s.x, s.y), s.radius, ringPaint);
    }

    // 2. Draw Particles
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);

      // White core
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * 0.45, corePaint);
    }

    // 3. Draw Floating Combo & Level Up Text
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
            Shadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              blurRadius: 14,
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

    // 4. Draw Flying Score Badges (Moving towards Total Score!)
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

      // Glowing shadow
      final glowPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(rect, glowPaint);

      // Gradient background
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF10B981)],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, bgPaint);

      // Gold border
      final borderPaint = Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rect, borderPaint);

      // Draw text centered
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
