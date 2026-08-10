import 'dart:async';

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
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitUp]);
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
    // groundY を利用してスライダーの top を計算
    final groundY = widget.game.blockSize * InvaderGame.groundLineDot;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottom = screenHeight - groundY; // groundY から下までの距離

    return Positioned(
      left: 80, //8, // 左寄せ
      bottom: bottom, // 地面ラインにぴったり
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Volume', style: TextStyle(color: Colors.white)),
            Slider(
              value: _volume,
              min: 0,
              max: 1,
              divisions: 10,
              label: (_volume * 100).round().toString(),
              activeColor: Colors.blueAccent, // スライダーの「塗られた部分」
              // inactiveColor: Colors.grey,  // スライダーの「残り部分」
              thumbColor: Colors.green, // つまみ（ドラッグする丸）の色
              onChanged: (value) {
                setState(() => _volume = value);
                AudioManager().setMasterVolume(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
