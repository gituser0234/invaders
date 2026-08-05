import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:invaders/game/defense_block.dart';
import 'package:invaders/game/invader_game.dart';
import 'package:invaders/game/player.dart';


/// 敵砲弾
// class EnemyBullet extends PositionComponent with CollisionCallbacks, HasGameReference<InvaderGame> {
class EnemyBullet extends RectangleComponent with CollisionCallbacks, HasGameReference<InvaderGame> {

  // final double speed = 320.0; //300.0 ~ 420.0;
  double speed = 0; //弾スピード　300.0 ~ 420.0;
  // late Vector2 previousPosition; //高速移動によるすり抜け防止（トンネリング対策）
  static const double bulletWidth = 1;
  static const double bulletHeight = 3;


  /// コンストラクタ
  EnemyBullet({required Vector2 position})
      : super(position: position);
      

  @override
  void onLoad() {
    super.onLoad();
    speed = 80.0 * game.blockSize;

    size = Vector2(
      bulletWidth * game.blockSize,
      bulletHeight * game.blockSize,
    );
    add(RectangleHitbox());
    // previousPosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // final nextPosition = position + Vector2(0, speed * dt);
    final current = position.clone();
    final nextPosition = current + Vector2(0, speed * dt);
    // ブロックヒット判定
    for (final block in game.children.whereType<DefenseBlock>()) {
      if (block.hitLine(current, nextPosition, bulletHeight: size.y)) {
        removeFromParent();
        break;
      }
    }

    // 移動
    position = nextPosition;

    // 画面外
    // プレイヤー下端すぐで消す
    // groundY をプレイヤーの Y + 高さ + 1px に設定
    final player = game.player; // Player コンポーネント
    final groundY = player.position.y + player.size.y; // プレイヤー下端
    if (position.y + size.y / 2 >= groundY) {
      removeFromParent();
    }

    // プレイヤー弾と衝突判定は onCollision で処理
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    // プレーヤーヒット処理
    if (other is Player) {
      other.hit();
      removeFromParent();
    } 

  }
}

