import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';

import 'package:flutter/material.dart';
import 'package:invaders/game/invader_game.dart';


/// UFO の爆発エフェクト
class UFOExplosion extends Component {
  final Vector2 position;
  final double blockSize;
  double timer = 0;
  final double duration = 0.5;

  final int numParticles; // ドットの数
  final List<Vector2> velocities = [];
  final Random rnd = Random();
  // final double duration = 0.4; // 爆発の持続時間


  UFOExplosion({required this.position, required this.blockSize, this.numParticles = 10}) {
    // ランダムな速度を生成
    for (int i = 0; i < numParticles; i++) {
      final angle = rnd.nextDouble() * 2 * pi;
      final speed = rnd.nextDouble() * 60 + 40; // 40〜100 px/s
      velocities.add(Vector2(cos(angle), sin(angle)) * speed);
    }
  }

  @override
  void update(double dt) {
    timer += dt;
    if (timer >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.orangeAccent;
    final progress = 1 - (timer / duration); // 徐々に消える

    for (final v in velocities) {
      final offset = v * timer;
      canvas.drawRect(
        Rect.fromLTWH(
          position.x + offset.x,
          position.y + offset.y,
          blockSize * progress,
          blockSize * progress,
        ),
        paint,
      );
    }
/*
    final paint = Paint()..color = Colors.orange;
    final size = blockSize * 3;
    canvas.drawCircle(Offset(position.x + size / 2, position.y + size / 2), size, paint);
*/
  }
}

/// UFO のスコア表示エフェクト
class UFOScoreDisplay extends TextComponent with HasGameReference<InvaderGame> {
  double timer = 0;
  final double duration = 1.3; // 1.3秒で消える
  final Vector2 velocity = Vector2(0, -20); // 上に浮かぶ速度

  UFOScoreDisplay({
    required String text,
    required Vector2 position,
    TextPaint? textPaint,
  }) : super(
          text: text,
          position: position.clone(),
          // textRenderer: textPaint ?? TextPaint(
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontSize: 4 * game.textScale, //16,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    textRenderer = TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: 4 * game.textScale, //16,
        fontWeight: FontWeight.bold,
      ),
    );

  }


  @override
  void update(double dt) {
    super.update(dt);
    timer += dt;
    // 上に浮かぶ
    position += velocity * dt;

    // 消える
    if (timer >= duration) removeFromParent();
  }
}
