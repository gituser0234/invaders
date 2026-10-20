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
              final gameWidth = widget.game.baseWidth * widget.game.blockSize;
              final gameHeight = widget.game.baseHeight * widget.game.blockSize;
              final scale = math.min(
                constraints.maxWidth / gameWidth,
                constraints.maxHeight / gameHeight,
              );
              final viewportWidth = gameWidth * scale;
              final viewportHeight = gameHeight * scale;
              final viewportLeft = (constraints.maxWidth - viewportWidth) / 2;
              final viewportTop = (constraints.maxHeight - viewportHeight) / 2;
              final viewportBottomGap =
                  constraints.maxHeight - viewportTop - viewportHeight;
              final groundY =
                  viewportTop +
                  InvaderGame.groundLineDot * widget.game.blockSize * scale;
              final isTitle = state == GameState.title;
              final bottom = isTitle
                  ? viewportBottomGap + 12
                  : constraints.maxHeight - groundY + 8;
              final sliderWidth = math.min(
                220.0,
                math.max(0.0, viewportWidth - 24),
              );

              return Stack(
                children: [
                  Positioned(
                    left: viewportLeft + 12,
                    bottom: bottom,
                    child: Container(
                      width: sliderWidth,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Volume',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Slider(
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
