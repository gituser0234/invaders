import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'package:invaders/game/audio_manager.dart';
import 'package:invaders/game/defense_block.dart';
import 'package:invaders/game/enemy.dart';
import 'package:invaders/game/invader_game.dart';

/// 敵管理
class EnemyManager extends Component with HasGameReference<InvaderGame> {
  late double step; // 1回の移動量（横）

  final double dropStep = 16; // 端での基本下降量（ゲーム座標）

  double direction = 1; // 1:右, -1:左

  // 敵移動タイマー
  double moveInterval = 0.5; //0.4;    // 0.4秒に一回移動 → ゆっくり動く
  double timer = 0;

  final totalEnemies = 12 * 5; // 初期敵数

  // 端判定（はみ出さないように余裕を持つ）
  static const double edgeMargin = 2.0; // ドット換算で余白

  final baseInterval = 0.5; // 全員いるときの間隔
  final exponent = 2; //0.5;      // 0.5:平方根でやや緩やか、1:線形、2:急加速

  double clearTimer = 0;
  bool clearTriggered = false;

  // 敵進行音のタイマー
  double soundTimer = 0;
  double soundInterval = 0.0; //0.55; //0.35;

  @override
  void onLoad() {
    super.onLoad();
    step = 1 * game.blockSize; // 1回の移動量（横）
  }

  @override
  void update(double dt) {
    // Flame の update() は 同期処理前提
    // Future<void> update(double dt) async {
    super.update(dt);

    // ラウンドクリア後の待ち時間
    if (game.state == GameState.roundClear && clearTriggered) {
      clearTimer += dt;
      if (clearTimer >= 1.1) {
        clearTriggered = false;
        game.nextRound();
      }
      return;
    }

    // 敵取得
    // final enemies = game.children.whereType<Enemy>().toList();
    final enemies = game.world.children.whereType<Enemy>().toList();

    final currentEnemies = enemies.length;

    final soundRatio = currentEnemies / totalEnemies;
    // ==========================
    // 進軍音速度更新
    // ==========================
    // final ratio = soundEnemies / totalEnemies;
    // soundInterval = 0.12 + 0.30 * pow(ratio, 0.7);
    soundInterval = 0.18 + 0.40 * pow(soundRatio, 0.7);

    // ==========================
    // 進軍音タイマー
    // ==========================
    soundTimer += dt;
    if (soundTimer >= soundInterval) {
      soundTimer = 0;
      AudioManager().playInvaderStep();
    }

    // ==========================
    // 敵移動タイマー
    // ==========================
    timer += dt;
    if (timer < moveInterval) return;
    timer = 0;

    // final enemies = game.children.whereType<Enemy>().toList();
    // ゲームクリア判定
    if (enemies.isEmpty && game.state == GameState.playing) {
      print("  enemies.isEmpty  GAME CLEAR,  NEXT GAME");
      // ステータス変更
      game.state = GameState.roundClear;
      // UFO音消す
      AudioManager().stopUfo();
      // 少しポーズ
      // await Future.delayed(const Duration(milliseconds: 900));
      clearTimer = 0;
      clearTriggered = true;
      return;
    }

    // 本家風に残り敵が少なくなると速くなる
    // final currentEnemies = enemies.length;
    // final baseInterval = 0.5;  // 全員いるときの間隔
    // final exponent = 2; //0.5;      // 0.5:平方根でやや緩やか、1:線形、2:急加速
    moveInterval = baseInterval * pow(currentEnemies / totalEnemies, exponent);
    // debugPrint("enemy=$currentEnemies moveInterval=$moveInterval");
    // 最低速度制限
    // if (moveInterval < 0.12) {
    //   moveInterval = 0.12;
    // }
    if (moveInterval < 0.02) {
      moveInterval = 0.015;
    }

    // 最後の１匹処理
    if (currentEnemies == 1) {
      // step = 1.5 * game.blockSize; // 6; // 1.3〜1.8くらいが本家感
      step = 1.9 * game.blockSize; // 6; // 1.3〜1.8くらいが本家感
    }

    // 敵全体を横に移動
    bool hitEdge = false;

    for (final e in enemies) {
      e.x += step * direction;

      if ((direction < 0 && e.x <= edgeMargin) ||
          (direction > 0 && e.x + e.width >= game.size.x - edgeMargin)) {
        hitEdge = true;
      }

      // 敵が盾の上にいる場合、毎フレーム削る
      for (final block in game.world.children.whereType<DefenseBlock>()) {
        // for (final block in game.children.whereType<DefenseBlock>()) {
        final enemyRect = Rect.fromLTWH(e.x, e.y, e.width, e.height);
        block.hitFromWorld(enemyRect); // 既存のメソッドをそのまま使う
      }
    }

    // 端に当たったら横移動を取り消し、隙間に合わせて下降する。
    if (hitEdge) {
      for (final e in enemies) {
        // 端を越えた横移動を取り消す。
        e.x -= step * direction;
      }

      // すでに砲台に接している場合、次の下降タイミングでゲームオーバー。
      var lowestEnemyBottom = enemies.first.y + enemies.first.height;
      for (final enemy in enemies.skip(1)) {
        final enemyBottom = enemy.y + enemy.height;
        if (enemyBottom > lowestEnemyBottom) {
          lowestEnemyBottom = enemyBottom;
        }
      }
      final gap = game.player.y - lowestEnemyBottom;
      if (gap <= 0) {
        AudioManager().playExplosion();
        game.onGameOver();
        return;
      }

      // 基本下降量より隙間が小さいときは、敵の底辺を砲台の先頭に合わせる。
      final descent = min(dropStep, gap).toDouble();
      for (final enemy in enemies) {
        enemy.y += descent;
      }
      direction *= -1;
    }
  }
}
