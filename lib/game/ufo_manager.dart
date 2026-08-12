import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:invaders/game/audio_manager.dart';
import 'package:invaders/game/invader_game.dart';
import 'package:invaders/game/ufo.dart';

class UFOManager extends Component with HasGameReference<InvaderGame> {
  final double blockSize;
  final List<List<List<int>>> shapes;
  final Color color;

  UFO? activeUFO;
  double timer = 0;
  late double nextSpawnTime = 0;

  // 出現位置（相対位置で管理）
  double ufoY = 0.0; // 初期値 0
  double ufoLeftX = 0.0; // 左端から出現
  double ufoRightX = 0.0; // 右端から出現

  late final double ufoWidth;
  late final double worldWidth;
  late final double worldHeight;
  static const margin = 2.0;

  UFOManager({required this.blockSize, required this.shapes, this.color = Colors.yellow}) {
    // UFOの出現間隔を初期化
    // nextSpawnTime = 3 + Random().nextDouble() * 5;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    ufoWidth = shapes[0][0].length * blockSize;

    // 論理ゲームエリアサイズ（固定）
    worldWidth = game.baseWidth * blockSize;
    worldHeight = game.baseHeight * blockSize;

    // 左右出現位置
    ufoLeftX = -ufoWidth - margin; // 左端は完全に画面外
    ufoRightX = worldWidth + margin; // 右端はゲームエリア右端ちょっと外
    // 出現Y位置（ゲームエリア内の相対位置）
    ufoY = worldHeight * 0.067; //0.065;
    //　UFOの出現間隔を初期化
    nextSpawnTime = 20 + Random().nextDouble() * 10; // 本家に近い間隔。ショット数は数えないでランダムで調整
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 画面上に UFO が存在する場合は生成しない
    if (activeUFO != null && activeUFO!.isMounted) return;

    timer += dt;
    if (timer < nextSpawnTime) return;
    timer = 0;

    // nextSpawnTime = 3 + Random().nextDouble() * 5;//デバッグで短めに設定
    nextSpawnTime = 20 + Random().nextDouble() * 10; // 本家に近い間隔。ショット数は数えないでランダムで調整

    // 出現方向を一度だけ決定
    final fromLeft = Random().nextBool();
    final ufoX = fromLeft ? ufoLeftX : ufoRightX;

    final ufoSpeed = fromLeft ? 20 * game.blockSize : -20 * game.blockSize;

    // 効果音再生
    AudioManager().playUfo();

    final ufo = UFO(
      position: Vector2(ufoX, ufoY),
      blockSize: blockSize,
      shapes: shapes,
      color: color,
      speed: ufoSpeed,
      worldWidth: worldWidth,
      onUfoRemove: () => activeUFO = null, // 削除時にフラグリセット
    );

    // game.add(ufo);
    game.world.add(ufo);

    activeUFO = ufo;
  }
}
