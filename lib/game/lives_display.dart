import 'package:flame/components.dart';

import 'package:invaders/game/player.dart';
import 'invader_game.dart'; // 自分のゲーム本体クラス

/// 残機表示
class LivesDisplay extends PositionComponent with HasGameReference<InvaderGame> {

  /// 残機数
  int lives;

  static const double marginDot = 2;    // 地面から何ドット下

  LivesDisplay({required this.lives});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.topLeft;

    final groundY = InvaderGame.groundLineDot * game.blockSize;

    position = Vector2(
      2.0 * game.blockSize,
      groundY + marginDot * game.blockSize,
    );

    _buildLives();
  }

  /// 残機アイコンを構築
  void _buildLives() {
    // removeAll(children);
    removeAll(children.toList());

    const spacingDot = 4.0;

    final playerWidth =
        Player.dotWidth * game.blockSize;

    for (int i = 0; i < lives; i++) {
      add(
        PlayerLifeIcon(blockSize: game.blockSize, shape: Player.playerShape)
          ..position = Vector2(
            i * (playerWidth + spacingDot * game.blockSize),
            0,
          ),
      );
    }
  }

  /// 残機数を更新
  void setLives(int newLives) {
    lives = newLives;
    _buildLives();
  }
}
