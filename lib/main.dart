
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invaders/game/audio_manager.dart';
import 'package:invaders/game/invader_game.dart';


Future<void> main() async {
  await Hive.initFlutter(); // Hive を Flutter 用に初期化
  await Hive.openBox<int>('highscore'); // ハイスコア用のボックスを開く
  
  // runApp(GameWidget(game: InvaderGame()));

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


/*
  runApp(
    Center(
      child: SizedBox(
        width: 896,  // baseWidth * _blockSize
        height: 1024, // baseHeight * _blockSize
        child: GameWidget(
          game: InvaderGame(),
          overlayBuilderMap: {
            'TouchUI': (context, game) => TouchControls(game: game as InvaderGame),
          },
          initialActiveOverlays: ['TouchUI'],
        ),
      ),
    ),
  );
*/

/*
  runApp(
    Center(
      child: SizedBox(
        width: 224 * 4.toDouble(),   // baseWidth * _blockSize
        height: 256 * 4.toDouble(),  // baseHeight * _blockSize
        child: GameWidget(
          game: InvaderGame(),
        ),
      ),
    ),
  );
*/

/*
  runApp(
    LayoutBuilder(
      builder: (context, constraints) {
        // 論理ゲームサイズ
        const baseWidth = 224;
        const baseHeight = 256;
        const blockSize = 4; // 常に固定

        final gameWidth = baseWidth * blockSize;   // 896
        final gameHeight = baseHeight * blockSize; // 1024

        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // アスペクト比を保った縮小スケール
        final scaleX = screenWidth / gameWidth;
        final scaleY = screenHeight / gameHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        return Center(
          child: SizedBox(
            width: gameWidth.toDouble(),
            height: gameHeight.toDouble(),
            child: Transform.scale(
              scale: scale < 1.0 ? scale : 1.0, // 1.0以上は拡大せず
              alignment: Alignment.topLeft,      // 左上基準で縮小
              child: GameWidget(
                game: InvaderGame(),
              ),
            ),
          ),
        );
      },
    ),
  );
*/
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
  }

  @override
  Widget build(BuildContext context) {
    // groundY を利用してスライダーの top を計算
    final groundY = widget.game.blockSize * InvaderGame.groundLineDot; 
    final screenHeight = MediaQuery.of(context).size.height;
    final bottom = screenHeight - groundY; // groundY から下までの距離

    return Positioned(
      left: 8,           // 左寄せ
      bottom: bottom,    // 地面ラインにぴったり
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:  0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Volume',
              style: TextStyle(color: Colors.white),
            ),
            Slider(
              value: _volume,
              min: 0,
              max: 1,
              divisions: 10,
              label: (_volume * 100).round().toString(),
              activeColor: Colors.blueAccent,   // スライダーの「塗られた部分」
              // inactiveColor: Colors.grey,  // スライダーの「残り部分」
              thumbColor: Colors.green,      // つまみ（ドラッグする丸）の色
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
