import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// デバッグ用グリッド表示
class DebugGrid extends PositionComponent {
  final double blockSize;
  final int logicalWidth;
  final int logicalHeight;

  DebugGrid({
    required this.blockSize,
    required this.logicalWidth,
    required this.logicalHeight,
  });

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    final widthPx = logicalWidth * blockSize;
    final heightPx = logicalHeight * blockSize;

    // 縦線
    for (int x = 0; x <= logicalWidth; x++) {
      final dx = x * blockSize;
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, heightPx),
        paint,
      );
    }

    // 横線
    for (int y = 0; y <= logicalHeight; y++) {
      final dy = y * blockSize;
      canvas.drawLine(
        Offset(0, dy),
        Offset(widthPx, dy),
        paint,
      );
    }

  }
}
