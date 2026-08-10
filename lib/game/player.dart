import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:invaders/game/audio_manager.dart';
import 'package:invaders/game/explosion.dart';

import 'package:invaders/game/invader_game.dart';
import 'bullet.dart';

///  Player（砲台）
class Player extends PositionComponent with HasGameReference<InvaderGame>, CollisionCallbacks {
  final double blockSize; // 外部から渡す

  bool canShoot = true; // 弾が消えたら true に戻す
  //int life = 3;//3;

  // 砲台
  static const List<List<int>> playerShape = [
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0], // 上部
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0], // 2段目
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // 中央（弾が出る部分）
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // 4段目
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // 下段
  ];

  static const int dotWidth = 11;
  static const int dotHeight = 5;

  // final Paint paint = Paint()..color = Colors.green;

  // 移動速度  200.0 → 遅い  300.0 → まあまあ  400.0 → Space Invaders っぽい  600.0 → 速すぎ
  late final double speed;

  bool isDead = false;

  final Paint paint = Paint()..color = Colors.blue;

  /// コンストラクタ
  Player({required Vector2 position, required this.blockSize}) : super(position: position) {
    add(RectangleHitbox());
    size = Vector2(playerShape[0].length * blockSize, playerShape.length * blockSize);
  }

  /// 初期化
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 移動速度設定
    speed = 75.0 * blockSize;
  }

  /// 描画
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // final paint = Paint()..color = Colors.blue;
    for (int y = 0; y < playerShape.length; y++) {
      for (int x = 0; x < playerShape[y].length; x++) {
        if (playerShape[y][x] == 1) {
          canvas.drawRect(Rect.fromLTWH(x * blockSize, y * blockSize, blockSize, blockSize), paint);
        }
      }
    }
  }

  /// 左移動
  void moveLeft(double dt) {
    position.x -= speed * dt;
    _clampToScreen();
  }

  /// 右移動
  void moveRight(double dt) {
    position.x += speed * dt;
    _clampToScreen();
  }

  /// 画面からはみ出ないようにする
  void _clampToScreen() {
    position.x = position.x.clamp(0.0, game.baseWidth * blockSize - size.x);
  }

  /// 砲撃
  void shoot(FlameGame game) {
    if (!canShoot) return;
    // シュート音を再生
    AudioManager().playShoot();

    final bullet = Bullet(owner: this, position: Vector2(position.x + size.x / 2 - 1, position.y - 5));
    // game.add(bullet);
    game.world.add(bullet);
    canShoot = false; // 弾が出ている間は発射不可（フラグ更新はbullet側で更新）
  }

  /// 被弾処理
  void hit() {
    if (isDead) return;
    // 爆発音を再生
    AudioManager().playExplosion();
    isDead = true;

    print("Player hit!");

    // 爆発エフェクト
    // game.add(Explosion(position: position.clone()));
    game.world.add(Explosion(position: position.clone()));

    // プレイヤー消滅
    removeFromParent();

    // ゲーム側の残機処理
    game.loseLife();
  }
}

/// プレーヤー残機のアイコン表示用コンポーネント
class PlayerLifeIcon extends PositionComponent {
  final double blockSize;

  final List<List<int>> shape;
  final paint = Paint()..color = Colors.green;

  PlayerLifeIcon({required this.blockSize, required this.shape}) {
    size = Vector2(Player.dotWidth * blockSize, Player.dotHeight * blockSize);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 1) {
          canvas.drawRect(Rect.fromLTWH(x * blockSize, y * blockSize, blockSize, blockSize), paint);
        }
      }
    }
  }
}
