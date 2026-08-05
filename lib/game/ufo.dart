import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:invaders/game/audio_manager.dart';
import 'package:invaders/game/bullet.dart';

import 'package:invaders/game/invader_game.dart';
import 'package:invaders/game/ufo_explosion.dart';



/// UFO
class UFO extends PositionComponent with CollisionCallbacks, HasGameReference<InvaderGame> {
  final double blockSize;
  final List<List<List<int>>> shapes;
  final Color color;
  final double speed;
  final VoidCallback? onUfoRemove;
  int shapeIndex = 0;
  double animTimer = 0;
  double animSpeed = 0.2;
  bool destroyed = false;
  // スコアをランダムで 50, 100, 150, 300
  final scores = [50, 100, 150, 300];
  late final double worldWidth;

  UFO({
    required Vector2 position,
    required this.blockSize,
    required this.shapes,
    required this.color,
    required this.speed,
    required this.worldWidth,
    this.onUfoRemove,
  }) : super(position: position) {
    anchor = Anchor.topLeft;
    size = Vector2(shapes[0][0].length * blockSize, shapes[0].length * blockSize);
    add(RectangleHitbox());
  }


  @override
  void update(double dt) {
    super.update(dt);

    // 移動とアニメーション
    if (!destroyed) {
      position.x += speed * dt;

      animTimer += dt;
      if (animTimer >= animSpeed) {
        animTimer = 0;
        shapeIndex = (shapeIndex + 1) % shapes.length;
      }


      // ゲームエリア外に出たら削除
      if ((speed > 0 && position.x > worldWidth) || (speed < 0 && position.x + size.x < 0)) {
        AudioManager().stopUfo();
        removeFromParent();
        onUfoRemove?.call();
      }

    }

  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // 弾と衝突
    if (!destroyed && other is Bullet) {

      // 効果音再生
      AudioManager().stopUfo();
      AudioManager().playHitUfo();
      destroyed = true;
      removeFromParent();
      onUfoRemove?.call();

      final score = scores[Random().nextInt(scores.length)];
      game.addScore(score);

      // ドット爆発エフェクト
      game.add(UFOExplosion(position: position.clone(), blockSize: blockSize, numParticles: 12));


      // 浮かぶスコア表示
      game.add(UFOScoreDisplay(
        text: score.toString(),
        position: position.clone() + Vector2(size.x / 2, -10), // UFO の上に表示
      ));

      other.removeFromParent();
    }
  }

  /// UFO の描画
  @override
  void render(Canvas canvas) {
    if (destroyed) return;

    final paint = Paint()..color = color;
    final shape = shapes[shapeIndex];

    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(x * blockSize, y * blockSize, blockSize, blockSize),
            paint,
          );
        }
      }
    }

    // // Hitbox 可視化
    // canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()
    //   ..color = const Color.fromARGB(255, 95, 54, 244).withOpacity(0.5)
    //   ..style = PaintingStyle.fill
    // );
  }
}

