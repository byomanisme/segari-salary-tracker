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
    required this.part,
    this.bodyIndex = 0,
    this.totalBodyLength = 4,
    this.direction = const Point(1, 0),
    this.animTick = 0,
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
      case 'catfish':
        _paintCatfish(canvas, size, w, h);
        break;
      case 'cat':
        _paintCat(canvas, size, w, h);
        break;
      case 'duck':
        _paintDuck(canvas, size, w, h);
        break;
      case 'rabbit':
        _paintRabbit(canvas, size, w, h);
        break;
      case 'snake':
      default:
        _paintSnake(canvas, size, w, h);
        break;
    }

    canvas.restore();
  }

  // ==========================================
  // 🐍 1. ULAR HIJAU SEGARI (SNAKE)
  // ==========================================
  void _paintSnake(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    if (part == MascotPart.head) {
      // Snake Head (Diamond/Teardrop Pixel Shape)
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

      // Eyes (White + Black Slit Pupil)
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.65, h * 0.32), w * 0.12, paint);
      paint.color = const Color(0xFF064E3B);
      canvas.drawCircle(Offset(w * 0.70, h * 0.32), w * 0.06, paint);

      // Flicking Red Forked Tongue 👅 (Animated)
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
  // 🐛 2. ULAT SAYUR SEGARI (CATERPILLAR)
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
  // 🐟 3. IKAN LELE SEGARI (CATFISH)
  // ==========================================
  void _paintCatfish(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    if (part == MascotPart.head) {
      // Catfish Head (Streamlined Torpedo + Whiskers)
      paint.color = const Color(0xFF06B6D4);
      final head = Path()
        ..moveTo(w * 0.1, h * 0.25)
        ..lineTo(w * 0.8, h * 0.35)
        ..lineTo(w * 0.95, h * 0.50) // Mouth
        ..lineTo(w * 0.8, h * 0.65)
        ..lineTo(w * 0.1, h * 0.75)
        ..close();
      canvas.drawPath(head, paint);

      // Dorsal Fin on top
      paint.color = const Color(0xFF0891B2);
      final dorsal = Path()
        ..moveTo(w * 0.3, h * 0.25)
        ..lineTo(w * 0.5, h * 0.05)
        ..lineTo(w * 0.7, h * 0.30)
        ..close();
      canvas.drawPath(dorsal, paint);

      // Long Catfish Whiskers (Kumis Lele) swaying with animTick!
      final sway = (animTick % 2 == 0) ? -h * 0.10 : h * 0.10;
      paint.color = const Color(0xFF67E8F9);
      paint.strokeWidth = 1.3;
      paint.style = PaintingStyle.stroke;
      final whiskerTop = Path()
        ..moveTo(w * 0.90, h * 0.46)
        ..quadraticBezierTo(w * 1.15, h * 0.25 + sway, w * 1.30, h * 0.15 + sway * 1.5);
      final whiskerBot = Path()
        ..moveTo(w * 0.90, h * 0.54)
        ..quadraticBezierTo(w * 1.15, h * 0.75 - sway, w * 1.30, h * 0.85 - sway * 1.5);
      canvas.drawPath(whiskerTop, paint);
      canvas.drawPath(whiskerBot, paint);
      paint.style = PaintingStyle.fill;

      // Fish Eye
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.68, h * 0.38), w * 0.11, paint);
      paint.color = const Color(0xFF0F172A);
      canvas.drawCircle(Offset(w * 0.73, h * 0.38), w * 0.05, paint);
    } else if (part == MascotPart.body) {
      // Catfish Body with side fin
      final fade = (1.0 - (bodyIndex * 0.12)).clamp(0.6, 1.0);
      paint.color = const Color(0xFF06B6D4).withOpacity(fade);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.22, w * 0.9, h * 0.56),
        Radius.circular(w * 0.2),
      );
      canvas.drawRRect(rrect, paint);

      // Pectoral side fin
      paint.color = const Color(0xFF38BDF8).withOpacity(fade);
      final fin = Path()
        ..moveTo(w * 0.45, h * 0.65)
        ..lineTo(w * 0.30, h * 0.90)
        ..lineTo(w * 0.60, h * 0.72)
        ..close();
      canvas.drawPath(fin, paint);
    } else {
      // Catfish Caudal Tail (Ekor Lele Bercabang Dua & Berenang)
      final finFlip = (animTick % 2 == 0) ? -h * 0.14 : h * 0.14;
      paint.color = const Color(0xFF0891B2);
      final tailFin = Path()
        ..moveTo(w * 0.85, h * 0.35)
        ..lineTo(w * 0.85, h * 0.65)
        ..lineTo(w * 0.40, h * 0.50)
        ..lineTo(w * 0.05, h * 0.15 + finFlip) // Top fin lobe
        ..quadraticBezierTo(w * 0.20, h * 0.50, w * 0.05, h * 0.85 + finFlip) // Bottom fin lobe
        ..lineTo(w * 0.40, h * 0.50)
        ..close();
      canvas.drawPath(tailFin, paint);

      // Tail fin ray shine
      paint.color = const Color(0xFF67E8F9);
      canvas.drawCircle(Offset(w * 0.45, h * 0.50), w * 0.09, paint);
    }
  }

  // ==========================================
  // 🐱 4. KUCING GUDANG SEGARI (CAT)
  // ==========================================
  void _paintCat(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    if (part == MascotPart.head) {
      // Cat Head with Pointy Ears 🐱
      paint.color = const Color(0xFFF59E0B); // Orange Tabby
      canvas.drawCircle(Offset(w * 0.50, h * 0.52), w * 0.36, paint);

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

      // Green Cat Eyes with black slit
      paint.color = const Color(0xFF10B981);
      canvas.drawCircle(Offset(w * 0.70, h * 0.48), w * 0.10, paint);
      paint.color = const Color(0xFF0F172A);
      canvas.drawRect(Rect.fromLTWH(w * 0.69, h * 0.40, w * 0.04, h * 0.16), paint);

      // Pink Nose & Whiskers
      paint.color = const Color(0xFFF472B6);
      canvas.drawCircle(Offset(w * 0.85, h * 0.56), w * 0.05, paint);

      // Tiny Golden Bell Collar
      paint.color = const Color(0xFFEF4444);
      canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.75, w * 0.45, h * 0.10), paint);
      paint.color = const Color(0xFFFBBF24);
      canvas.drawCircle(Offset(w * 0.38, h * 0.80), w * 0.07, paint);
    } else if (part == MascotPart.body) {
      // Cat Tabby Body + Paws
      final fade = (1.0 - (bodyIndex * 0.12)).clamp(0.6, 1.0);
      paint.color = const Color(0xFFF59E0B).withOpacity(fade);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.25, w * 0.8, h * 0.55),
        Radius.circular(w * 0.2),
      );
      canvas.drawRRect(rrect, paint);

      // Tabby Stripes
      paint.color = const Color(0xFFB45309).withOpacity(fade);
      canvas.drawRect(Rect.fromLTWH(w * 0.45, h * 0.25, w * 0.10, h * 0.35), paint);

      // White Cat Paws
      final pawStep = ((bodyIndex + animTick) % 2 == 0) ? -h * 0.04 : h * 0.04;
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.32, h * 0.80 + pawStep), w * 0.08, paint);
      canvas.drawCircle(Offset(w * 0.68, h * 0.80 - pawStep), w * 0.08, paint);
    } else {
      // Real Cat Tail (Ekor Kucing Melengkung S & Goyang)
      final sway = (animTick % 2 == 0) ? -h * 0.15 : h * 0.15;
      paint.color = const Color(0xFFD97706);
      paint.strokeWidth = w * 0.22;
      paint.style = PaintingStyle.stroke;
      paint.strokeCap = StrokeCap.round;

      final tail = Path()
        ..moveTo(w * 0.8, h * 0.55)
        ..cubicTo(w * 0.5, h * 0.70 + sway, w * 0.3, h * 0.25 + sway, w * 0.10, h * 0.15 + sway * 1.5);
      canvas.drawPath(tail, paint);
      paint.style = PaintingStyle.fill;

      // White Fluffy Tail Tip
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.10, h * 0.15 + sway * 1.5), w * 0.14, paint);
    }
  }

  // ==========================================
  // 🦆 5. BEBEK PETERNAK SEGARI (DUCK)
  // ==========================================
  void _paintDuck(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    if (part == MascotPart.head) {
      // Duck Head (Yellow + Orange Bill)
      paint.color = const Color(0xFFEAB308);
      canvas.drawCircle(Offset(w * 0.48, h * 0.48), w * 0.36, paint);

      // Orange Duck Bill / Beak 🦆
      paint.color = const Color(0xFFF97316);
      final beak = Path()
        ..moveTo(w * 0.70, h * 0.42)
        ..lineTo(w * 1.05, h * 0.50)
        ..lineTo(w * 0.70, h * 0.62)
        ..close();
      canvas.drawPath(beak, paint);

      // Duck Eye
      paint.color = const Color(0xFF0F172A);
      canvas.drawCircle(Offset(w * 0.60, h * 0.38), w * 0.09, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.63, h * 0.35), w * 0.03, paint);

      // Farmer Feather Tuft on top
      paint.color = const Color(0xFF10B981);
      final tuft = Path()
        ..moveTo(w * 0.35, h * 0.18)
        ..lineTo(w * 0.45, h * 0.02)
        ..lineTo(w * 0.55, h * 0.18)
        ..close();
      canvas.drawPath(tuft, paint);
    } else if (part == MascotPart.body) {
      // Duck Body with Flapping Wing
      final fade = (1.0 - (bodyIndex * 0.12)).clamp(0.6, 1.0);
      paint.color = const Color(0xFFEAB308).withOpacity(fade);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.25, w * 0.8, h * 0.55),
        Radius.circular(w * 0.25),
      );
      canvas.drawRRect(rrect, paint);

      // Flapping Wing
      final wingFlap = (animTick % 2 == 0) ? -h * 0.08 : h * 0.08;
      paint.color = const Color(0xFFFDE047).withOpacity(fade);
      final wing = Path()
        ..moveTo(w * 0.35, h * 0.35)
        ..quadraticBezierTo(w * 0.65, h * 0.20 + wingFlap, w * 0.55, h * 0.60)
        ..close();
      canvas.drawPath(wing, paint);

      // Orange Webbed Paddling Feet
      paint.color = const Color(0xFFEA580C);
      canvas.drawCircle(Offset(w * 0.40, h * 0.84), w * 0.08, paint);
      canvas.drawCircle(Offset(w * 0.65, h * 0.84), w * 0.08, paint);
    } else {
      // Real Duck Pointy Upward Tail Feathers (Ekor Bebek Menungging)
      final wag = (animTick % 2 == 0) ? -h * 0.10 : h * 0.10;
      paint.color = const Color(0xFFCA8A04);
      final duckTail = Path()
        ..moveTo(w * 0.8, h * 0.40)
        ..lineTo(w * 0.8, h * 0.70)
        ..lineTo(w * 0.35, h * 0.65)
        ..lineTo(w * 0.05, h * 0.15 + wag) // Pointed upward duck tail
        ..lineTo(w * 0.40, h * 0.40)
        ..close();
      canvas.drawPath(duckTail, paint);

      // Tail feather streak
      paint.color = const Color(0xFFFEF08A);
      canvas.drawCircle(Offset(w * 0.20, h * 0.28 + wag), w * 0.08, paint);
    }
  }

  // ==========================================
  // 🐰 6. KELINCI WORTEL SEGARI (RABBIT)
  // ==========================================
  void _paintRabbit(Canvas canvas, Size size, double w, double h) {
    final paint = Paint()..isAntiAlias = true;

    if (part == MascotPart.head) {
      // Rabbit Head with Long Upright Ears 🐰
      paint.color = const Color(0xFFEC4899); // Cute Bunny Pink
      canvas.drawCircle(Offset(w * 0.48, h * 0.55), w * 0.35, paint);

      // Long Bouncy Bunny Ears
      final earTwitch = (animTick % 2 == 0) ? -w * 0.06 : w * 0.06;
      paint.color = const Color(0xFFDB2777);
      final earL = Path()
        ..moveTo(w * 0.25, h * 0.40)
        ..lineTo(w * 0.18 + earTwitch, h * 0.02)
        ..lineTo(w * 0.40, h * 0.30)
        ..close();
      final earR = Path()
        ..moveTo(w * 0.50, h * 0.30)
        ..lineTo(w * 0.68 - earTwitch, h * 0.02)
        ..lineTo(w * 0.75, h * 0.40)
        ..close();
      canvas.drawPath(earL, paint);
      canvas.drawPath(earR, paint);

      // Pink Inner Ears
      paint.color = const Color(0xFFFBCFE8);
      canvas.drawCircle(Offset(w * 0.28, h * 0.20), w * 0.06, paint);
      canvas.drawCircle(Offset(w * 0.62, h * 0.20), w * 0.06, paint);

      // Bunny Eye with Sparkle
      paint.color = const Color(0xFF831843);
      canvas.drawCircle(Offset(w * 0.68, h * 0.52), w * 0.09, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.71, h * 0.49), w * 0.03, paint);

      // Pink Bunny Nose & Tooth
      paint.color = const Color(0xFFF43F5E);
      canvas.drawCircle(Offset(w * 0.84, h * 0.60), w * 0.05, paint);
      paint.color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(w * 0.80, h * 0.66, w * 0.07, h * 0.08), paint);
    } else if (part == MascotPart.body) {
      // Rabbit Body + White Fluffy Belly
      final fade = (1.0 - (bodyIndex * 0.12)).clamp(0.6, 1.0);
      paint.color = const Color(0xFFEC4899).withOpacity(fade);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.25, w * 0.8, h * 0.55),
        Radius.circular(w * 0.25),
      );
      canvas.drawRRect(rrect, paint);

      // White Bunny Belly
      paint.color = Colors.white.withOpacity(0.9 * fade);
      canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.18, paint);

      // Cute Hopping Paws
      final hop = ((bodyIndex + animTick) % 2 == 0) ? -h * 0.05 : h * 0.05;
      paint.color = const Color(0xFFFBCFE8);
      canvas.drawCircle(Offset(w * 0.35, h * 0.82 + hop), w * 0.08, paint);
      canvas.drawCircle(Offset(w * 0.65, h * 0.82 - hop), w * 0.08, paint);
    } else {
      // Real Bunny Tail (Ekor Bulat Berbulu Kapas / Fluffy Cotton Puff)
      final bob = (animTick % 2 == 0) ? -h * 0.08 : h * 0.08;
      paint.color = const Color(0xFFDB2777);
      canvas.drawCircle(Offset(w * 0.65, h * 0.50), w * 0.24, paint);

      // Fluffy White Cotton Ball Tail
      paint.color = Colors.white;
      canvas.drawCircle(Offset(w * 0.25, h * 0.50 + bob), w * 0.22, paint);

      // Pink Shadow on Puff
      paint.color = const Color(0xFFFBCFE8);
      canvas.drawCircle(Offset(w * 0.32, h * 0.56 + bob), w * 0.10, paint);
    }
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
