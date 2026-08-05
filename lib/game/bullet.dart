import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:invaders/game/defense_block.dart';
import 'package:invaders/game/enemy_bullet.dart';
import 'package:invaders/game/enemy_explosion.dart';
import 'package:invaders/game/invader_game.dart';
import 'package:invaders/game/player.dart';
import 'enemy.dart';

/// プレーヤー砲弾
class Bullet extends RectangleComponent
    with CollisionCallbacks, HasGameReference<InvaderGame> {

  static const double bulletWidth = 1;
  static const double bulletHeight = 3;

  /// コンストラクタ
  Bullet({required this.owner, required Vector2 position})
      : super(position: position);

  final Player owner; // 弾の発射元プレイヤー

  // final Paint paint = Paint()..color = Colors.red;
  @override
  Paint get paint => _paint;
  final Paint _paint = Paint()..color = Colors.red;

  double speed = 150; // 弾の速度  　520.0 ~ 600.0;

  late Vector2 previousPosition;
  bool hasHitBlock = false; // ブロックに当たったかどうかのフラグ


  @override
  void onLoad() {
    super.onLoad();
    
    size = Vector2(
      bulletWidth * game.blockSize,
      bulletHeight * game.blockSize,
    );
    // 衝突判定用の矩形を追加
    add(RectangleHitbox());
    previousPosition = position.clone();

    speed = 150.0 * game.blockSize;
   
  }


  @override
  void update(double dt) {
    super.update(dt);

    final nextPosition = position + Vector2(0, -speed * dt);

    // すべてのブロックに対して線分ヒットチェック
    for (final block in game.children.whereType<DefenseBlock>()) {
      if (block.hitLine(previousPosition, nextPosition, bulletHeight: size.y)) {
      // if (block.hitLine(previousPosition, nextPosition)) {

        removeFromParent();
        break; // 1ブロックヒットで弾消える
      }
    }


    // ★ UFO / Enemy 用の CollisionCallbacks に任せる
    // previousPosition = position.clone();//フレームのメモリ確保が発生
    position.copyInto(previousPosition); // メモリ確保なしで前回位置を更新
    position = nextPosition;

    // 画面外判定
    if (position.y + size.y < 0) {
      removeFromParent();
    }

  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), paint);
  }


  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other); // mustCallSuperに対応
    if (other is Enemy) {
      // ヒット音再生
      //AudioManager().playHit();
      other.removeFromParent(); // 敵 を消す
      removeFromParent();

      // 敵爆発エフェクト（サイズは敵の半分くらい）
      game.add(EnemyExplosion(
        position: other.position + other.size / 2, // 中心に移動
        crossSize: other.size.x * 0.4,
      ));
      
      // スコア加算
      game.addScore(other.score);

    } else if (other is EnemyBullet) {
      // プレイヤー弾と敵弾が衝突
      other.removeFromParent();
      removeFromParent();
    }
 
  }

 
  @override
  void onRemove() {
    super.onRemove();

    final players = game.children.whereType<Player>();
    if (players.isNotEmpty) {
      players.first.canShoot = true;
    }
  }

}
