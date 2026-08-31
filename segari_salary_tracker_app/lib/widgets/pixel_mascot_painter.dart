import 'dart:math';
import 'package:flutter/material.dart';

enum MascotPart { head, body, tail }

class PixelMascotWidget extends StatelessWidget {
  final String skinId;
  final MascotPart part;
  final int bodyIndex;
  final int totalBodyLength;
  final Point<int> direction;
  final int animTick;
  final double size;

  const PixelMascotWidget({
    Key? key,
    required this.skinId,
    this.part = MascotPart.head,
    this.bodyIndex = 0,
    this.totalBodyLength = 1,
    this.direction = const Point(1, 0),
    this.animTick = 0,
    int? frameIndex,
    this.size = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PixelMascotPainter(
          skinId: skinId,
          part: part,
          bodyIndex: bodyIndex,
          totalBodyLength: totalBodyLength,
          direction: direction,
          animTick: animTick,
        ),
      ),
    );
  }
}

class PixelMascotPainter extends CustomPainter {
  final String skinId;
  final MascotPart part;
  final int bodyIndex;
  final int totalBodyLength;
  final Point<int> direction;
  final int animTick;

  PixelMascotPainter({
    required this.skinId,
    required this.part,
    required this.bodyIndex,
    required this.totalBodyLength,
    required this.direction,
    required this.animTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // Apply rotation based on movement direction (1,0)=0 rad, (0,1)=pi/2, (-1,0)=pi, (0,-1)=-pi/2
    double angle = 0.0;
    if (direction.x == 1 && direction.y == 0) {
      angle = 0.0;
    } else if (direction.x == -1 && direction.y == 0) {
      angle = pi;
    } else if (direction.x == 0 && direction.y == 1) {
      angle = pi / 2;
    } else if (direction.x == 0 && direction.y == -1) {
      angle = -pi / 2;
    }

    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);

    switch (skinId) {
      case 'caterpillar':
        _paintCaterpillar(canvas, size, w, h);
        break;
      case 'cat':
        _paintCat(canvas, size, w, h);
        break;
      case 'chicken':
        _paintChicken(canvas, size, w, h);
        break;
      case 'snake':
      default:
        _paintSnake(canvas, size, w, h);
        break;
    }

    canvas.restore();
  }

  // ==========================================
  // 🐍 1. ULAR HIJAU SEGARI (SNAKE - Multi-Segment)
  // ==========================================
  void _paintSnake(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    if (part == MascotPart.head) {
      // Snake Head (Diamond/Teardrop Shape)
      paint.color = const Color(0xFF10B981); // Emerald
      final headPath = Path()
        ..moveTo(w * 0.15, h * 0.25)
        ..lineTo(w * 0.85, h * 0.35)
        ..lineTo(w * 0.95, h * 0.50) // Nose tip
        ..lineTo(w * 0.85, h * 0.65)
        ..lineTo(w * 0.15, h * 0.75)
        ..close();
      canvas.drawPath(headPath, paint);

      // Top Scale Highlight
      paint.color = const Color(0xFF34D399);
      canvas.drawCircle(Offset(w * 0.5, h * 0.4), w * 0.18, paint);

      // Eyes (White + Slit Pupil)
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.65, h * 0.32), w * 0.12, paint);
      paint.color = const Color(0xFF064E3B);
      canvas.drawCircle(Offset(w * 0.70, h * 0.32), w * 0.06, paint);

      // Animated Red Forked Tongue 👅
      if (animTick % 2 == 0) {
        paint.color = const Color(0xFFEF4444);
        paint.strokeWidth = 1.3;
        paint.style = PaintingStyle.stroke;
        final tongue = Path()
          ..moveTo(w * 0.95, h * 0.50)
          ..lineTo(w * 1.18, h * 0.50)
          ..lineTo(w * 1.28, h * 0.42)
          ..moveTo(w * 1.18, h * 0.50)
          ..lineTo(w * 1.28, h * 0.58);
        canvas.drawPath(tongue, paint);
        paint.style = PaintingStyle.fill;
      }
    } else if (part == MascotPart.body) {
      // Snake Body Segment with Diamond Scales
      final fade = (1.0 - (bodyIndex * 0.12)).clamp(0.6, 1.0);
      paint.color = const Color(0xFF10B981).withOpacity(fade);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.6),
        Radius.circular(w * 0.25),
      );
      canvas.drawRRect(rrect, paint);

      // Underbelly Stripe
      paint.color = const Color(0xFFA7F3D0).withOpacity(fade);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.2, h * 0.5, w * 0.6, h * 0.22),
          Radius.circular(w * 0.1),
        ),
        paint,
      );

      // Diamond scale center dot
      paint.color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.08, paint);
    } else {
      // Snake Tail (Tapered Pointy Wiggling Tail)
      final wiggle = (animTick % 2 == 0) ? -h * 0.12 : h * 0.12;
      paint.color = const Color(0xFF059669);
      final tailPath = Path()
        ..moveTo(w * 0.8, h * 0.25)
        ..lineTo(w * 0.8, h * 0.75)
        ..quadraticBezierTo(w * 0.4, h * 0.5 + wiggle, w * 0.05, h * 0.5 + wiggle * 1.5)
        ..close();
      canvas.drawPath(tailPath, paint);

      // Tail Tip Highlight
      paint.color = const Color(0xFF34D399);
      canvas.drawCircle(Offset(w * 0.15, h * 0.5 + wiggle * 1.2), w * 0.08, paint);
    }
  }

  // ==========================================
  // 🐛 2. ULAT SAYUR SEGARI (CATERPILLAR - Multi-Segment)
  // ==========================================
  void _paintCaterpillar(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    if (part == MascotPart.head) {
      // Caterpillar Head (Lime Green Chubby Circle)
      paint.color = const Color(0xFF84CC16);
      canvas.drawCircle(Offset(w * 0.55, h * 0.50), w * 0.38, paint);

      // Antennae with cute bulbs 🌿
      paint.color = const Color(0xFF4D7C0F);
      paint.strokeWidth = 1.4;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.60, h * 0.20), Offset(w * 0.75, h * 0.02), paint);
      canvas.drawLine(Offset(w * 0.40, h * 0.20), Offset(w * 0.25, h * 0.02), paint);
      paint.style = PaintingStyle.fill;

      paint.color = const Color(0xFFFDE047);
      canvas.drawCircle(Offset(w * 0.75, h * 0.02), w * 0.08, paint);
      canvas.drawCircle(Offset(w * 0.25, h * 0.02), w * 0.08, paint);

      // Big Kawaii Eye & Pink Blush
      paint.color = const Color(0xFF1E293B);
      canvas.drawCircle(Offset(w * 0.72, h * 0.45), w * 0.11, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.75, h * 0.42), w * 0.04, paint);

      // Pink Blush Cheek
      paint.color = const Color(0xFFF472B6).withOpacity(0.85);
      canvas.drawCircle(Offset(w * 0.65, h * 0.68), w * 0.09, paint);
    } else if (part == MascotPart.body) {
      // Caterpillar Body Segment (Plump sphere + animated crawling feet)
      final fade = (1.0 - (bodyIndex * 0.1)).clamp(0.6, 1.0);
      paint.color = const Color(0xFF84CC16).withOpacity(fade);
      canvas.drawCircle(Offset(w * 0.5, h * 0.48), w * 0.34, paint);

      // Yellow ring highlight
      paint.color = const Color(0xFFFDE047).withOpacity(fade);
      canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.12, paint);

      // Crawling Feet on bottom
      final footStep = ((bodyIndex + animTick) % 2 == 0) ? -h * 0.05 : h * 0.05;
      paint.color = const Color(0xFF3F6212);
      canvas.drawCircle(Offset(w * 0.35, h * 0.82 + footStep), w * 0.08, paint);
      canvas.drawCircle(Offset(w * 0.65, h * 0.82 - footStep), w * 0.08, paint);
    } else {
      // Caterpillar Tail (Rump with cute Fresh Leaf Sprout 🍃)
      paint.color = const Color(0xFF65A30D);
      canvas.drawCircle(Offset(w * 0.6, h * 0.5), w * 0.28, paint);

      // Leaf Sprout on Tail
      paint.color = const Color(0xFF22C55E);
      final leaf = Path()
        ..moveTo(w * 0.4, h * 0.5)
        ..quadraticBezierTo(w * 0.15, h * 0.25, w * 0.05, h * 0.35)
        ..quadraticBezierTo(w * 0.20, h * 0.65, w * 0.4, h * 0.5);
      canvas.drawPath(leaf, paint);
    }
  }

  // ==========================================
  // 🐱 3. KUCING GUDANG SEGARI (CAT - 1 Kotak Saja)
  // ==========================================
  void _paintCat(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    // Cat Body / Head in 1 compact cell
    paint.color = const Color(0xFFF59E0B); // Orange Tabby
    canvas.drawCircle(Offset(w * 0.50, h * 0.52), w * 0.38, paint);

    // Pointy Ears
    paint.color = const Color(0xFFD97706);
    final earL = Path()
      ..moveTo(w * 0.22, h * 0.35)
      ..lineTo(w * 0.15, h * 0.05)
      ..lineTo(w * 0.45, h * 0.25)
      ..close();
    final earR = Path()
      ..moveTo(w * 0.55, h * 0.25)
      ..lineTo(w * 0.85, h * 0.05)
      ..lineTo(w * 0.78, h * 0.35)
      ..close();
    canvas.drawPath(earL, paint);
    canvas.drawPath(earR, paint);

    // Pink Inner Ears
    paint.color = const Color(0xFFFDA4AF);
    canvas.drawCircle(Offset(w * 0.28, h * 0.22), w * 0.07, paint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.22), w * 0.07, paint);

    // Tabby Forehead Stripes
    paint.color = const Color(0xFFB45309);
    canvas.drawRect(Rect.fromLTWH(w * 0.47, h * 0.25, w * 0.06, h * 0.14), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.28, w * 0.05, h * 0.10), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.57, h * 0.28, w * 0.05, h * 0.10), paint);

    // Green Cat Eyes with slit
    paint.color = const Color(0xFF10B981);
    canvas.drawCircle(Offset(w * 0.70, h * 0.48), w * 0.10, paint);
    canvas.drawCircle(Offset(w * 0.38, h * 0.48), w * 0.10, paint);
    paint.color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(w * 0.69, h * 0.40, w * 0.035, h * 0.16), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.37, h * 0.40, w * 0.035, h * 0.16), paint);

    // Pink Nose & Muzzle
    paint.color = const Color(0xFFF472B6);
    canvas.drawCircle(Offset(w * 0.54, h * 0.60), w * 0.05, paint);

    // Whiskers
    paint.color = Colors.white;
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.75, h * 0.58), Offset(w * 0.96, h * 0.52), paint);
    canvas.drawLine(Offset(w * 0.75, h * 0.64), Offset(w * 0.96, h * 0.68), paint);
    paint.style = PaintingStyle.fill;

    // Tiny Golden Bell Collar
    paint.color = const Color(0xFFEF4444);
    canvas.drawRect(Rect.fromLTWH(w * 0.25, h * 0.80, w * 0.50, h * 0.09), paint);
    paint.color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(w * 0.50, h * 0.85), w * 0.07, paint);
  }

  // ==========================================
  // 🐔 4. AYAM PETERNAK SEGARI (CHICKEN - 1 Kotak Saja)
  // ==========================================
  void _paintChicken(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    // Chicken Body / Head in 1 compact cell (White / Cream)
    paint.color = const Color(0xFFF8FAFC);
    canvas.drawCircle(Offset(w * 0.50, h * 0.52), w * 0.38, paint);

    // Red Comb on Top 🐔
    paint.color = const Color(0xFFEF4444);
    final comb = Path()
      ..moveTo(w * 0.30, h * 0.25)
      ..lineTo(w * 0.35, h * 0.06)
      ..lineTo(w * 0.48, h * 0.18)
      ..lineTo(w * 0.58, h * 0.04)
      ..lineTo(w * 0.68, h * 0.18)
      ..lineTo(w * 0.75, h * 0.08)
      ..lineTo(w * 0.78, h * 0.28)
      ..close();
    canvas.drawPath(comb, paint);

    // Red Wattle below beak
    paint.color = const Color(0xFFDC2626);
    canvas.drawCircle(Offset(w * 0.75, h * 0.68), w * 0.08, paint);

    // Orange Beak 🐥
    paint.color = const Color(0xFFF97316);
    final beak = Path()
      ..moveTo(w * 0.68, h * 0.44)
      ..lineTo(w * 0.98, h * 0.52)
      ..lineTo(w * 0.68, h * 0.60)
      ..close();
    canvas.drawPath(beak, paint);

    // Eye
    paint.color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(w * 0.58, h * 0.42), w * 0.08, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.60, h * 0.39), w * 0.03, paint);

    // Wing Feather Accent on side
    paint.color = const Color(0xFFE2E8F0);
    final wing = Path()
      ..moveTo(w * 0.18, h * 0.48)
      ..quadraticBezierTo(w * 0.38, h * 0.40, w * 0.42, h * 0.65)
      ..quadraticBezierTo(w * 0.25, h * 0.75, w * 0.18, h * 0.48);
    canvas.drawPath(wing, paint);
  }

  @override
  bool shouldRepaint(covariant PixelMascotPainter oldDelegate) {
    return oldDelegate.skinId != skinId ||
        oldDelegate.part != part ||
        oldDelegate.bodyIndex != bodyIndex ||
        oldDelegate.direction != direction ||
        oldDelegate.animTick != animTick;
  }
}
