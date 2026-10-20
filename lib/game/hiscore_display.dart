import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:invaders/game/invader_game.dart';

/// ハイスコア表示
class HiScoreDisplay extends Component with HasGameReference<InvaderGame> {
  late TextComponent label;
  late TextComponent value;

  double blinkTimer = 0;
  final double blinkInterval = 0.5;
  bool blinking = false;
  bool showValue = true;

  late TextPaint labelPaint;
  late TextPaint valuePaintVisible;
  late TextPaint valuePaintHidden;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // final labelFontSize = 20; // labelPaintで設定したfontSize
    final worldWidth = game.baseWidth * game.blockSize;

    //
    labelPaint = TextPaint(
      style: TextStyle(
        color: const Color(0xFFFFFF00), // 黄色
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    );

    valuePaintVisible = TextPaint(
      style: TextStyle(
        color: const Color(0xFFFFFF00), // 黄色
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    );

    valuePaintHidden = TextPaint(
      style: TextStyle(
        color: const Color(0x00FFFF00), // 透明黄色
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    );

    // label = TextComponent(
    //   text: 'HI-SCORE',
    //   // position: Vector2(game.size.x / 2, 8), // ブロック2個分下
    //   position: Vector2(worldWidth / 2, 8), // ブロック2個分下
    //   anchor: Anchor.topCenter,
    //   textRenderer: labelPaint,
    // );

    // value = TextComponent(
    //   // text: game.getHighScore().toString().padLeft(4, '0'),
    //   text: game.getHighScore().toString(),
    //   position: Vector2(
    //     worldWidth / 2,
    //     8 + labelFontSize * 1.2, // 文字サイズの1.2倍下に配置
    //   ),
    //   anchor: Anchor.topCenter,
    //   textRenderer: valuePaintVisible,
    // );

    final centerX = worldWidth / 2 - 40;
    final y = 4.0;
    final gap = 4.0;

    label = TextComponent(text: 'HI-SCORE : ', position: Vector2(centerX, y), anchor: Anchor.topLeft, textRenderer: labelPaint);

    value = TextComponent(
      text: game.getHighScore().toString(),
      position: Vector2(centerX + label.width + gap, y),
      anchor: Anchor.topLeft,
      textRenderer: valuePaintVisible,
    );

    add(label);
    add(value);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!blinking) return;

    blinkTimer += dt;
    if (blinkTimer >= blinkInterval) {
      blinkTimer = 0;
      showValue = !showValue;

      // TextPaint を差し替える（←これが効く）
      value.textRenderer = showValue ? valuePaintVisible : valuePaintHidden;
    }
  }

  /// ハイスコア更新処理
  void onHiScoreUpdated(int newScore) {
    // value.text = newScore.toString().padLeft(4, '0');
    value.text = newScore.toString();
    blinking = true;
    blinkTimer = 0;
    showValue = true;
    value.textRenderer = valuePaintVisible;
  }

  /// 点滅停止
  void stopBlink() {
    blinking = false;
    value.textRenderer = valuePaintVisible;
  }
}
