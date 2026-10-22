import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invaders/game/audio_manager.dart';
import 'package:invaders/game/invader_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 最初に呼ぶ

  await Hive.initFlutter(); // Hive を Flutter 用に初期化
  await Hive.openBox<int>('highscore'); // ハイスコア用のボックスを開く

  // ★ Web（PCブラウザ等）ではない、ネイティブアプリ（iOS/Android）の時だけ実行
  if (!kIsWeb) {
    // ★ スマホのステータスバーとナビゲーションバーを隠して完全フルスクリーンにする
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 横画面に固定する場合
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitUp]);
    // await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  runApp(
    MaterialApp(
      title: 'Invader Game',
      home: Scaffold(
        body: SafeArea(
          child: GameWidget(
            game: InvaderGame(),
            // Overlay 登録
            overlayBuilderMap: {
              'VolumeOverlay': (BuildContext context, InvaderGame game) {
                return VolumeControlOverlay(game: game);
              },
            },
            // 最初から表示
            initialActiveOverlays: const ['VolumeOverlay'],
          ),
        ),
      ),
    ),
  );
}

/// Flutter側：スライダーを表示するウィジェット
class VolumeControlOverlay extends StatefulWidget {
  final InvaderGame game;

  const VolumeControlOverlay({super.key, required this.game});

  @override
  State<VolumeControlOverlay> createState() => _VolumeControlOverlayState();
}

class _VolumeControlOverlayState extends State<VolumeControlOverlay> {
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _volume = AudioManager().masterVolume; // 初期音量を取得
    debugPrint(" 初期音量  $_volume");
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ValueListenableBuilder<GameState>(
        valueListenable: widget.game.stateListenable,
        builder: (context, state, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // 固定論理サイズのゲーム画面が収まる倍率と表示領域を求める。
              final gameWidth = widget.game.baseWidth * widget.game.blockSize;
              final gameHeight = widget.game.baseHeight * widget.game.blockSize;
              final scale = math.min(constraints.maxWidth / gameWidth, constraints.maxHeight / gameHeight);
              final viewportWidth = gameWidth * scale;
              final viewportHeight = gameHeight * scale;
              final viewportLeft = (constraints.maxWidth - viewportWidth) / 2;
              final viewportTop = (constraints.maxHeight - viewportHeight) / 2;
              final viewportBottomGap = constraints.maxHeight - viewportTop - viewportHeight;
              final groundY = viewportTop + InvaderGame.groundLineDot * widget.game.blockSize * scale;
              // タイトルでは表示領域の左下、プレイ中は地上線の少し上に置く。
              final isTitle = state == GameState.title;
              // 画面幅に応じて操作部品を縮小し、小さくなりすぎないよう下限を設ける。
              final controlScale = (viewportWidth / 600).clamp(0.65, 1.0);
              final bottom = isTitle ? viewportBottomGap + 12 * controlScale : constraints.maxHeight - groundY + 8 * controlScale;
              final sliderWidth = math.min(220 * controlScale, math.max(0.0, viewportWidth - 24 * controlScale));

              return Stack(
                children: [
                  // ==========================================
                  // 追加：上部のかっこいいタイトル表示
                  // ==========================================
                  Positioned(
                    top: viewportTop + 24 * scale,
                    left: viewportLeft,
                    width: viewportWidth,
                    child: Center(
                      child: Text(
                        'INVADER GAME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 100 * controlScale,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 4.0 * controlScale,
                          shadows: [
                            Shadow(color: Colors.cyanAccent, blurRadius: 12, offset: Offset(0, 0)),
                            Shadow(color: Colors.blue, blurRadius: 20, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 既存のボリュームスライダー
                  Positioned(
                    left: viewportLeft + 12 * controlScale,
                    bottom: bottom,
                    child: Container(
                      width: sliderWidth,
                      padding: EdgeInsets.all(2 * controlScale),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8 * controlScale)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Volume',
                            style: TextStyle(color: Colors.white, fontSize: 16 * controlScale, fontWeight: FontWeight.bold),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4 * controlScale,
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10 * controlScale),
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 16 * controlScale),
                            ),
                            child: Slider(
                              value: _volume,
                              min: 0,
                              max: 1,
                              divisions: 10,
                              label: (_volume * 100).round().toString(),
                              activeColor: Colors.blueAccent,
                              thumbColor: Colors.green,
                              onChanged: (value) {
                                setState(() => _volume = value);
                                AudioManager().setMasterVolume(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
