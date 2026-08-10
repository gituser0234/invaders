import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

/// 防御ブロック
class DefenseBlock extends PositionComponent with CollisionCallbacks {
  final double blockSize; //10;

  final List<List<int>> shieldShape = [
    [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1],
  ];

  // 個別のドットコンポーネントを管理
  // final List<RectangleComponent> dots = [];

  DefenseBlock({required Vector2 position, required this.blockSize}) : super(position: position) {
    anchor = Anchor.topLeft; // ★これ最重要
    // 描画サイズをブロック数に合わせて設定
    size = Vector2(shieldShape[0].length * blockSize, shieldShape.length * blockSize);

    // ブロック全体のヒットボックス
    add(RectangleHitbox()..collisionType = CollisionType.passive); //TODO: world使えない
  }

  /// 線分ヒット判定
  /// プレーヤー、敵弾共通で使用
  bool hitLine(Vector2 start, Vector2 end, {double bulletHeight = 3}) {
    final from = start - position;
    final to = end - position;

    final distance = to - from;
    // final steps = (distance.length / blockSize).ceil().clamp(1, 100);//ベクトルのユークリッド距離なので弾が斜めに飛ばないのでy方向のみで判定
    final steps = (distance.y.abs() / blockSize).ceil().clamp(1, 100);

    final stepVector = distance / steps.toDouble(); // ← int → double に変換
    //final bulletHeight = blockSize * 4; // ← ここが「元の4ドット」

    for (int i = 0; i <= steps; i++) {
      final point = from + stepVector * i.toDouble();
      final x = (point.x ~/ blockSize);
      // final y = (point.y ~/ blockSize);
      for (double dy = 0; dy < bulletHeight; dy += blockSize) {
        final y = ((point.y + dy) ~/ blockSize);

        if (x < 0 || x >= shieldShape[0].length || y < 0 || y >= shieldShape.length) continue;

        if (shieldShape[y][x] == 1) {
          shieldShape[y][x] = 0; // 1ドット消す
          return true; // ヒットしたら終了
        }
      }
    }
    return false; // ヒットなし
  }

  bool isEmpty() => shieldShape.every((row) => row.every((v) => v == 0));

  final Paint paint = Paint()..color = Colors.brown;

  @override
  void render(Canvas canvas) {
    for (int y = 0; y < shieldShape.length; y++) {
      for (int x = 0; x < shieldShape[y].length; x++) {
        if (shieldShape[y][x] == 1) {
          canvas.drawRect(Rect.fromLTWH(x * blockSize, y * blockSize, blockSize, blockSize), paint);
        }
      }
    }
  }

  // bool hitEnemy(Vector2 worldPos) {
  //   // ★ Flame 正式のローカル変換
  //   final localStart = absoluteToLocal(worldPos);
  //   final localEnd   = localStart + Vector2(0, blockSize * 3);

  //   return hitLine(localStart, localEnd);
  // }

  void hitFromWorld(Rect enemyRect) {
    final double blockDotSize = blockSize;
    const double margin = 2;

    final rows = shieldShape.length;
    final cols = shieldShape[0].length;

    final expandedEnemy = enemyRect.inflate(margin);

    final worldPos = absolutePosition; // ★これ

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (shieldShape[y][x] == 1) {
          final dotRect = Rect.fromLTWH(worldPos.x + x * blockDotSize, worldPos.y + y * blockDotSize, blockDotSize, blockDotSize);

          if (expandedEnemy.overlaps(dotRect)) {
            shieldShape[y][x] = 0;
          }
        }
      }
    }
  }

  // @override
  // void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
  //   // print("DefenseBlock collided with ${other.runtimeType}");
  //   super.onCollision(intersectionPoints, other); // mustCallSuperに対応
  //   // if (other is Enemy) {
  //   //   // 敵の底辺中央
  //   //   final enemyBottom = other.position + Vector2(other.size.x / 2, other.size.y);
  //   //
  //   //   // 上から下に向けて "線を伸ばして" ヒット判定
  //   //   final start = enemyBottom;
  //   //   final end   = enemyBottom + Vector2(0, blockSize * 2);
  //   //
  //   //   hitLine(start, end);
  //   // }
  // }
}
