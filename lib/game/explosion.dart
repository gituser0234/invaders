import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:invaders/game/invader_game.dart';

/// 本家スペースインベーダー風：白い破片が飛び散る爆発
class Explosion extends PositionComponent with HasGameReference {
  // final Vector2 position;

  /// 破片（4つ）
  // final List<_Fragment> fragments = [];
  final List<_Fragment> _fragments = []; // ← _fragments に変更

  Explosion({required Vector2 position}) {
    this.position = position.clone();        // ★これ必須
    size = Vector2.all(0);                   // 当たり判定用ではないので 0 でOK
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 上・右・下・左の4方向へ破片を飛ばす
    _fragments.addAll([
      _Fragment(direction: Vector2(0, -1)),  // 上
      _Fragment(direction: Vector2(1, 0)),   // 右
      _Fragment(direction: Vector2(0, 1)),   // 下
      _Fragment(direction: Vector2(-1, 0)),  // 左
    ]);

    // Game に追加可能にする
    for (final f in _fragments) {
      add(f);
    }
  }

  @override
  void update(double dt) {
    // すべての破片が消えたら、この Explosion も消す
    if (children.isEmpty) {
      removeFromParent();
    }
  }
}

/// 飛び散る破片
class _Fragment extends PositionComponent with HasGameReference<InvaderGame>{
  final Vector2 direction;
  late final double speed;
  double lifetime = 0.19; //0.18; // 本家くらいの短さ
  final Paint paint = Paint()..color = const Color(0xFFFFFFFF);
  late final Vector2 velocity;


  _Fragment({required this.direction}) {
    // size = Vector2.all(6); // 白い小さい四角
    // anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async{
    await super.onLoad();

    speed = 30 * game.blockSize;
    size = Vector2.all(2 * game.blockSize); // ← 2ドット分とか
    anchor = Anchor.center;
    velocity = direction.normalized() * speed;
  }


  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 移動
    position += velocity * dt;

    // 一瞬で消える
    lifetime -= dt;
    if (lifetime <= 0) {
      removeFromParent();
    }
  }
}
