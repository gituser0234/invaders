import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:invaders/game/enemy_bullet.dart';
import 'package:invaders/game/invader_game.dart';



///　敵　インベーダー
class Enemy extends PositionComponent with HasGameReference<InvaderGame>{
// class Enemy extends PositionComponent with CollisionCallbacks, HasGameReference<InvaderGame>{
  final double blockSize;
  final List<List<List<int>>> shapes;
  final Color color;         // ★ 敵の色を外から指定
  int shapeIndex = 0;
  late final Paint paint;

  double animTimer = 0;
  double animSpeed = 0.3;

  // final double shootInterval = 1.5; // ランダムタイマーにする場合は +ランダム値
  final int score; // ← 追加

  Enemy({
    required Vector2 position,
    required this.blockSize,
    required this.shapes,
    required this.color,     // ★ 必須パラメータに
    required this.score,  // 必須に
  }) : super(position: position) {
    anchor = Anchor.topLeft; // ★これを追加
    paint = Paint()..color = color;

    size = Vector2(
      shapes[0][0].length * blockSize,
      shapes[0].length * blockSize,
    );
    // 衝突判定用の矩形を追加
    add(RectangleHitbox());
  }
  

  @override
  void update(double dt) {
    super.update(dt);

    animTimer += dt;
    if (animTimer >= animSpeed) {
      animTimer = 0;
      shapeIndex = (shapeIndex + 1) % shapes.length;
    }
  }

  /// 攻撃
  void shoot() {
    // 画面上の敵弾が最大3発まで
    final currentEnemyBullets = game.children.whereType<EnemyBullet>().length;
    if (currentEnemyBullets >= 3) return;

    // 弾の X 座標を敵中央に
    final bulletX = position.x + (size.x - EnemyBullet.bulletWidth) / 2; // 弾の幅が4なら中央に合わせる
    final bulletY = position.y + size.y;

    final bullet = EnemyBullet(position: Vector2(bulletX, bulletY));
    game.add(bullet);

  }

  @override
  void render(Canvas canvas) {
    // final paint = Paint()..color = color;   // ★ 指定色で描画
    final shape = shapes[shapeIndex];
    final len = shape.length;
    for (int y = 0; y < len; y++) {
      final lenY = shape[y].length;
      for (int x = 0; x < lenY; x++) {
        if (shape[y][x] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * blockSize,
              y * blockSize,
              blockSize,
              blockSize,
            ),
            paint,
          );
        }
      }
    }
  }
  
}
