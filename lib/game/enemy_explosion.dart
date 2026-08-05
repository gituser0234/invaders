import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:invaders/game/audio_manager.dart';
import 'package:invaders/game/invader_game.dart';


/// 敵用の爆発エフェクト（本家風・地味）
class EnemyExplosion extends PositionComponent with HasGameReference<InvaderGame> {
  double _lifetime = 0.1; // 表示時間 0.1秒
  late final double crossSize; // 爆発の大きさ（敵のサイズに合わせて調整）
  late final Paint paint;

  EnemyExplosion({
    required Vector2 position,
    this.crossSize = 2.0, // デフォルトで 2 ドットくらい
  }) : super(
          position: position.clone(),
          size: Vector2.all(crossSize), // 2ドットくらい
          anchor: Anchor.center,
        );

  @override
  void onLoad() {
  // Future<void> onLoad() async {
    super.onLoad();
    paint = Paint()..color = Colors.white;
    // 敵爆発用の短い効果音を再生
    AudioManager().enemyHit();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // final paint = Paint()..color = Colors.white;
    // 十字型にする場合
    final mid = size.x / 2;
    // 横線
    canvas.drawRect(Rect.fromLTWH(0, mid - 0.5, size.x, 1), paint);
    // 縦線
    canvas.drawRect(Rect.fromLTWH(mid - 0.5, 0, 1, size.y), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime -= dt;
    if (_lifetime <= 0) {
      removeFromParent();
    }
  }
}
