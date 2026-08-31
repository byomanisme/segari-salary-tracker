"import 'dart:math';
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
      ang
<truncated 19963 bytes>