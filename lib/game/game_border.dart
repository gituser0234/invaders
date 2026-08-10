import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// ゲームエリアの境界線
class GameBorder extends PositionComponent {
  final double blockSize;
  final int logicalWidth;
  final int logicalHeight;

  GameBorder({required this.blockSize, required this.logicalWidth, required this.logicalHeight});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.green
      // ..strokeWidth = 1
      ..strokeWidth =
          blockSize // * 0.5
      ..style = PaintingStyle.stroke;

    final widthPx = logicalWidth * blockSize;
    final heightPx = logicalHeight * blockSize;

    canvas.drawRect(Rect.fromLTWH(0, 0, widthPx, heightPx), paint);
  }
}
