import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invaders/game/audio_manager.dart';
import 'package:invaders/game/debug_grid.dart';
import 'package:invaders/game/defense_block.dart';
import 'package:invaders/game/enemy_bullet.dart';
import 'package:invaders/game/enemy_manager.dart';
import 'package:invaders/game/game_border.dart';
import 'package:invaders/game/hiscore_display.dart';
import 'package:invaders/game/lives_display.dart';
import 'package:invaders/game/ufo.dart';
import 'package:invaders/game/ufo_manager.dart';
import 'player.dart';
import 'enemy.dart';

///　ゲームステータス
enum GameState { title, playing, roundClear, gameOver }

/// 操作状態クラス
class InputState {
  bool left = false;
  bool right = false;
  bool fire = false;
}

/// インベーダゲーム
class InvaderGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  // class InvaderGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  // class InvaderGame extends FlameGame with HasCollisionDetection, KeyboardHandler, HasTappables {

  // 開発用フラグ: true → スマホ 1pxスケール, false → 開発用見やすい4pxスケール　ブラウザ
  static const bool useHighRes = false;
  static const bool showDebugGrid = false; //true; // デバッグ用グリッド

  bool get isMobile => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  // 論理サイズ（本家を想定）
  static const int _baseWidth = 224;
  static const int _baseHeight = 256;

  // 地面ライン
  static const int groundLineDot = 224;

  // ゲームサイズゲッター
  int get baseWidth => _baseWidth;
  int get baseHeight => _baseHeight;

  // ドットの表示サイズ
  late final double _blockSize;
  double get blockSize => _blockSize;

  // Player（砲台）
  late Player player;
  // Player（砲台）ドット幅
  static const int playerDotWidth = 11;

  double _enemyShootTimer = 0.0;
  final double _enemyShootInterval = 1.0; // 1秒ごとに射出判定
  int playerLives = 3;
  // bool _isGameOver = false;

  // Block（防御壁）ドット幅・高さ
  static const int blockDotHeight = 13;

  // カニ
  final crabShapes = [
    [
      [0, 1, 0, 0, 0, 1, 0],
      [0, 1, 0, 0, 0, 1, 0],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 0, 1],
      [1, 0, 1, 0, 1, 0, 1],
      [0, 0, 1, 0, 1, 0, 0],
    ],
    [
      [0, 1, 0, 0, 0, 1, 0],
      [0, 1, 0, 0, 0, 1, 0],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 0, 1],
      [0, 1, 0, 1, 0, 1, 0],
      [0, 0, 0, 1, 0, 0, 0],
    ],
    [
      [0, 1, 0, 0, 0, 1, 0],
      [0, 1, 0, 0, 0, 1, 0],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 0, 1],
      [1, 0, 1, 0, 1, 0, 1],
      [0, 1, 0, 0, 0, 1, 0],
    ],
  ];

  // イカ
  final squidShapes = [
    [
      [0, 0, 1, 0, 1, 0, 0],
      [0, 1, 0, 1, 0, 1, 0],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 0, 1],
      [0, 1, 0, 1, 0, 1, 0],
      [1, 0, 0, 1, 0, 0, 1],
    ],
    [
      [0, 0, 1, 0, 1, 0, 0],
      [0, 1, 0, 1, 0, 1, 0],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 0, 1],
      [1, 0, 1, 0, 0, 1, 0],
      [0, 1, 0, 1, 0, 1, 0],
    ],
  ];

  //　タコ
  final octopusShapes = [
    [
      [0, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 0, 1, 1, 0, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 0, 1, 1],
      [1, 0, 1, 1, 1, 0, 1, 1],
      [0, 1, 0, 0, 0, 1, 0, 0],
    ],
    [
      [0, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 0, 1, 1, 0, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 0, 1, 1],
      [0, 1, 0, 1, 0, 1, 0, 0],
      [1, 0, 1, 0, 0, 1, 0, 1],
    ],
  ];

  //　敵キャラの色リスト
  final enemyColors = [
    Colors.redAccent, // 上段
    Colors.orangeAccent, // 2段目
    Colors.yellowAccent, // 3段目
    Colors.greenAccent, // 4段目
    Colors.blueAccent, // 下段
  ];

  // UFOの形状
  final ufoShape = [
    [
      [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 1, 1, 1, 0, 1],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    ],
    [
      [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 1, 1, 1, 0, 1],
      [0, 1, 0, 1, 1, 1, 1, 0, 1, 0],
    ],
  ];

  // 操作入力状態
  late final InputState input = InputState();

  // スコア
  int score = 0;
  //　スコア表示
  late TextComponent scoreText;

  // ハイスコア管理用 Hive Box
  late Box<int> _hiScoreBox;

  // Web/モバイルでのオーディオロック解除済みフラグ
  // bool _audioUnlocked = false;
  // ハイスコア表示
  late HiScoreDisplay hiScoreDisplay;
  // プレイヤーのスコア表示用コンポーネント
  // late TextComponent playerScoreText;
  // 残機表示用コンポーネント
  late LivesDisplay livesDisplay;
  // ゲーム状態
  GameState state = GameState.title;
  // STARTメッセージ
  late StartMessage startMessage;
  // 敵管理
  late EnemyManager enemyManager;
  // ゲームROUND
  var currentRound = 1;
  // next game での追加下降量
  double initialDrop = 0.0;
  // ROUND数表示
  late TextComponent roundText;

  /// コンストラクタ
  InvaderGame() : super() {
    //ドットサイズ
    // _blockSize = useHighRes ? 1 : 4;
    _blockSize = 4; // ★ 常に4で固定

    // camera = CameraComponent.withFixedResolution(
    //   width: baseWidth * _blockSize.toDouble(),
    //   height: baseHeight * _blockSize.toDouble(),
    // )
    camera = CameraComponent.withFixedResolution(width: baseWidth * _blockSize, height: baseHeight * _blockSize)
      ..viewfinder.anchor = Anchor.topLeft
      ..viewfinder.position = Vector2.zero();

    // add(camera);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // AudioManager を初期化
    // await AudioManager().init();

    //ハイスコア取得
    _hiScoreBox = Hive.box<int>('highscore');

    // 初期値がなければ 0 をセット
    if (!_hiScoreBox.containsKey('hi')) {
      _hiScoreBox.put('hi', 0);
    }

    // ゲーム開始前に onLoad などで追加
    startMessage = StartMessage(
      size,
      gameRef: this,
      onStart: () async {
        startGame();
      },
    );

    // add(startMessage);
    world.add(startMessage);

    // Flame が用意している「開発用デバッグ表示」を有効化するスイッチです。
    // debugMode = true;
  }

  /// テキストスケール取得
  double get textScale {
    return useHighRes ? 1.0 : 4.0; // 高解像度: 1倍, 開発用: 4倍
  }

  /// 画面リサイズ処理
  /// 主にデバイスごとのスケーリング対応
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final gameWidth = baseWidth * _blockSize;
    final gameHeight = baseHeight * _blockSize;

    // final scaleX = size.x / gameWidth;
    // final scaleY = size.y / gameHeight;

    // アスペクト比を保つため小さい方を採用
    // final scale = scaleX < scaleY ? scaleX : scaleY;

    if (isMobile) {
      // ★ 全自動でアスペクト比を保ちつつ、画面内にピッタリ収まるように縮小・拡大するカメラをセット
      camera = CameraComponent.withFixedResolution(width: gameWidth, height: gameHeight);

      // ★ 原点を左上に固定（これで座標のズレを防ぎます）
      camera.viewfinder.anchor = Anchor.topLeft;
      camera.viewfinder.position = Vector2.zero();
    } else {
      // PCは等倍表示
      camera.viewfinder.zoom = 1.0; // PCは等倍
      camera.viewfinder.anchor = Anchor.topLeft;
      camera.viewfinder.position = Vector2.zero();
    }

    // debugPrint(' scale=$scale zoom=${camera.viewfinder.zoom}');
  }

  /// キーボード入力処理
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // KeyDownEvent を使う
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (state == GameState.title) {
          startGame(); // ゲーム開始処理
        }
      }
    }

    input.left = keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    input.right = keysPressed.contains(LogicalKeyboardKey.arrowRight);
    input.fire = keysPressed.contains(LogicalKeyboardKey.space);

    // ゲームオーバー時に R で再プレイ
    if (state == GameState.gameOver && event.logicalKey == LogicalKeyboardKey.keyR) {
      returnToTitle();
    }

    return KeyEventResult.handled;
  }

  /// ゲーム開始処理
  Future<void> startGame() async {
    // final sw = Stopwatch()..start();

    // debugPrint("startGame start");

    startMessage.removeFromParent(); // タイトル消去

    // ----------------------------------------------------
    // 2. 【先に】ゲームの基本要素（UI・自機・壁）を画面に配置する
    // ----------------------------------------------------

    // print("state:      $state");
    // ゲームクリア処理対応
    if (state != GameState.playing) {
      state = GameState.playing;
      playerLives = 3;
      score = 0;
    }

    // 敵射出タイマー初期化
    _enemyShootTimer = 0.0;

    // ハイスコア表示コンポーネント作成
    hiScoreDisplay = HiScoreDisplay();
    world.add(hiScoreDisplay);
    // add(hiScoreDisplay);

    // スコア表示を作成
    scoreText = TextComponent(
      text: 'SCORE: $score',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 10 * textScale, //24,
          // fontFamily: 'Courier',
        ),
      ),
      position: Vector2(3 * _blockSize, 1 * _blockSize), // 左上
    );
    // add(scoreText);
    world.add(scoreText);

    // // EnemyManager を追加
    // enemyManager = EnemyManager();
    // add(enemyManager);

    // Block（防御壁）配置
    makeDefenseBlock();

    // Player（砲台）配置
    spawnPlayer();

    // // Enemy 配置
    // spawnEnemy();

    // // UFO Manager 追加
    // add(UFOManager(blockSize: _blockSize, shapes: ufoShape, color: Colors.yellow));

    // 地面ライン
    // const int groundLineDot = 224;
    final groundY = groundLineDot * _blockSize;
    final groundLine = RectangleComponent(
      position: Vector2(0, groundY),
      size: Vector2(size.x, _blockSize), // ← 高さも blockSize に
      paint: Paint()..color = Colors.red,
      priority: 1000, // ← 重要！！
    );

    // add(groundLine);
    world.add(groundLine);

    // 残機表示を作成（地面ラインの少し下）
    livesDisplay = LivesDisplay(lives: playerLives);
    livesDisplay.position = Vector2(
      8, // 左端マージン
      groundY + 2 * _blockSize, // 地面から少し下に配置
    );

    // add(livesDisplay);
    world.add(livesDisplay);

    // ROUND表示
    createRoundDisplay();

    // モバイル用タッチ操作UI追加
    addTouchControls();

    // ゲームエリア境界線
    // final gameBorder = children.whereType<GameBorder>();
    final gameBorder = world.children.whereType<GameBorder>();
    if (gameBorder.isEmpty) {
      // add(GameBorder(blockSize: _blockSize, logicalWidth: baseWidth, logicalHeight: baseHeight));
      world.add(GameBorder(blockSize: _blockSize, logicalWidth: baseWidth, logicalHeight: baseHeight));
    }

    //　デバッグ用グリッド表示
    if (showDebugGrid) {
      // final debugGrids = children.whereType<DebugGrid>();
      final debugGrids = world.children.whereType<DebugGrid>();
      if (debugGrids.isEmpty) {
        // add(DebugGrid(blockSize: _blockSize, logicalWidth: baseWidth, logicalHeight: baseHeight));
        world.add(DebugGrid(blockSize: _blockSize, logicalWidth: baseWidth, logicalHeight: baseHeight));
      }
    }

    // ----------------------------------------------------
    // 3. 画面に要素が揃った状態で「READY...」演出を開始！
    // ----------------------------------------------------

    // 色々やってみたが、どうして初回起動時にブラウザの音声スタンバイが間に合わず1秒くらい遅れて開始し溜まっている進軍音が連発される。
    // しょうがないので、以下のエフェクトかまして１秒くらい時間を稼ぐ

    // ② 裏でオーディオの初期化を走らせる　起動フラグで管理してるので複数回やっても大丈夫
    final initFuture = AudioManager().init();

    // ③ 「READY...」を表示するための TextComponent を作成して画面のど真ん中に追加する
    final readyText = TextComponent(
      text: 'READY...',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 4.0, // ちょっと文字間隔を空けるとレトロ感が出ます
        ),
      ),
      anchor: Anchor.center,
      position: size / 2, // 画面の中央に配置
    );
    // add(readyText);
    world.add(readyText);

    // ④ 0.8秒待つ（この間、画面には「READY...」が表示されている）  ここの前でやれば1.2秒で十分だったが直前だとちょっと足りなった。
    // 環境によるので1.5秒くらいで確実に
    await Future.delayed(const Duration(milliseconds: 900));

    // ⑤ 文字を「GO!」に書き換える
    readyText.text = 'GO!';

    // ⑥ 万が一オーディオの初期化が終わっていなければここで確実に待ち、さらに0.4秒待つ
    await initFuture;
    await Future.delayed(const Duration(milliseconds: 700));

    // ⑦ 演出が終わったので「GO!」の文字を画面から消す
    // remove(readyText);
    world.remove(readyText);

    // ----------------------------------------------------
    // 4. 「GO!」が消えた瞬間に、敵を配置（進軍開始）！
    // ----------------------------------------------------

    // EnemyManager を追加
    enemyManager = EnemyManager();
    world.add(enemyManager);
    // Enemy 配置
    spawnEnemy();
    // UFO Manager 追加
    // add(UFOManager(blockSize: _blockSize, shapes: ufoShape, color: Colors.yellow));
    world.add(UFOManager(blockSize: _blockSize, shapes: ufoShape, color: Colors.yellow));

    // debugPrint("startGame end ${sw.elapsedMilliseconds}ms");
  }

  /// ネクストゲーム開始処理
  void nextRound() {
    // ラウンド進行
    currentRound++;
    // 敵開始位置算出
    initialDrop = enemyManager.dropStep * (currentRound - 1) * 2;

    // 敵・UFO・弾の掃除
    removeEnemies();
    removeEnemyBullets();
    removeUFOs();
    // 防御壁（再生成する方針なら）
    removeDefenseBlocks();

    // 残機表示削除
    // removeLivesDisplays();

    // 防御壁作成
    makeDefenseBlock();

    // プレイヤーは生存している前提
    resetPlayerPosition();

    //　敵配置
    spawnEnemy();

    // ROUND数更新表示
    updateRoundDisplay();
    // ステータスを playing に戻す
    state = GameState.playing;
  }

  /// 防御ブロック配置
  void makeDefenseBlock() {
    const int blockDotWidth = 22;
    final blockWidth = blockDotWidth * _blockSize;

    // 画面中央
    final centerX = size.x / 2;

    // ブロック間の隙間（本家感）
    final gap = blockWidth * 1.2; // 1.2倍ブロック幅くらい

    // ブロック数
    const int blockCount = 3;
    const int blockYDot = 176;
    final blockY = blockYDot * _blockSize;

    for (int i = 0; i < blockCount; i++) {
      final offset = (i - 1) * (blockWidth + gap); // 中央ブロック基準
      final posX = centerX + offset - blockWidth / 2;
      final block = DefenseBlock(position: Vector2(posX, blockY), blockSize: _blockSize);
      // add(block);
      world.add(block);
    }
  }

  /// 敵出現
  void spawnEnemy() {
    // 敵キャラの種類リスト
    final enemyTypes = [
      squidShapes, // 1段目（上）
      crabShapes, // 2段目
      crabShapes, // 3段目
      octopusShapes, // 4段目
      octopusShapes, // 5段目（下）
    ];

    // 行ごとのスコア
    final enemyScores = [
      30, // 上段：スコア高め
      20, // 中段
      20, // 中段
      10, // 下段
      10, // 下段
    ];

    // Enemy 配置
    final enemyCols = 12; //15; 本家は11-12らしい
    final enemyRows = 5;
    final spacingX = size.x / (enemyCols + 4); // 横間隔
    // final enemyTopMargin = size.y * 0.1;   // 画面上から 10%
    // final spacingY = size.y * 0.06;        // 行間を 6% に設定
    final enemyTopMargin = size.y * 0.12; //0.15; //0.40; //0.15;   // 画面上から 15% に変更
    final spacingY = size.y * 0.05; //0.065;        // 行間を少し広げる

    // 下降量算出
    enemyManager.dropStep = _blockSize * 2; //16;

    // 敵配置
    for (int row = 0; row < enemyRows; row++) {
      for (int col = 0; col < enemyCols; col++) {
        final posX = spacingX * (col + 1) - _blockSize * 1.5;
        //final posY = enemyTopMargin + row * spacingY;
        final posY = enemyTopMargin + row * spacingY + initialDrop; // ゲームクリアの度に下に配置させる

        world.add(
          // add(
          Enemy(
            position: Vector2(posX, posY),
            // blockSize: enemyBlockSize,
            blockSize: _blockSize,
            shapes: enemyTypes[row], // ← 行ごとに種類が変わる
            color: enemyColors[row],
            score: enemyScores[row], // 行ごとにスコア
          ),
        );
      }
    }
  }

  /// 砲台リセット
  void resetPlayerPosition() {
    // 既存プレイヤーがいる場合は削除
    player.removeFromParent();
    // 新規生成
    spawnPlayer();
  }

  /// 防御壁削除
  void removeDefenseBlocks() {
    // final block = children.whereType<DefenseBlock>().toList();
    final block = world.children.whereType<DefenseBlock>().toList();
    for (final b in block) {
      b.removeFromParent();
    }
  }

  /// 敵削除
  void removeEnemies() {
    // children の中から Enemy だけ抽出して remove
    // final enemies = children.whereType<Enemy>().toList(); // toList 重要！
    final enemies = world.children.whereType<Enemy>().toList(); // toList 重要！
    for (final e in enemies) {
      e.removeFromParent();
    }
  }

  /// 残機表示削除
  void removeLivesDisplays() {
    // children の中から LivesDisplay だけ抽出して remove
    // final livesDisplays = children.whereType<LivesDisplay>().toList(); // toList 重要！
    final livesDisplays = world.children.whereType<LivesDisplay>().toList(); // toList 重要！
    for (final l in livesDisplays) {
      l.removeFromParent();
    }
  }

  /// 敵弾丸削除
  void removeEnemyBullets() {
    // final bullets = children.whereType<EnemyBullet>().toList();
    final bullets = world.children.whereType<EnemyBullet>().toList();
    for (final b in bullets) {
      b.removeFromParent();
    }
  }

  /// UFO削除
  void removeUFOs() {
    // final ufos = children.whereType<UFO>().toList();
    final ufos = world.children.whereType<UFO>().toList();
    for (final u in ufos) {
      u.removeFromParent();
    }
  }

  /// プレイヤー出現
  void spawnPlayer() {
    // 画面中央
    final centerX = size.x / 2;
    const int blockDotWidth = 22;
    const int blockDotHeight = 13;
    final blockWidth = blockDotWidth * _blockSize;
    final blockHeight = blockDotHeight * _blockSize;
    const int playerDotWidth = 11;

    final playerWidth = playerDotWidth * _blockSize;

    // ブロック数
    const int blockYDot = 176;
    final blockY = blockYDot * _blockSize;

    // gap 1ドット（ほぼくっつき）
    const int gapDot = 1;

    // 中央ブロックX
    final centerBlockX = centerX - blockWidth / 2;

    // 砲台X（中央ブロック中央に揃える）
    final playerX = centerBlockX + blockWidth / 2 - playerWidth / 2;

    // 砲台Y（ブロック下 + gap）
    final playerY = blockY + blockHeight + gapDot * _blockSize;

    player = Player(position: Vector2(playerX, playerY), blockSize: _blockSize);
    // add(player);
    world.add(player);
  }

  /// 残機を1つ失う
  void loseLife() {
    playerLives--;
    print("残機: $playerLives");

    // 残機表示更新
    livesDisplay.setLives(playerLives);

    if (playerLives <= 0) {
      onGameOver();
      return;
    }

    // 1秒後に復活
    Future.delayed(const Duration(milliseconds: 900), () {
      spawnPlayer();
    });
  }

  /// ゲームオーバー処理
  void onGameOver() {
    // 画面中央に Game Over 表示
    if (state == GameState.gameOver) return;

    state = GameState.gameOver;

    // メッセージ
    world.add(
      // add(
      GameOverMessage(
        size,
        gameRef: this,
        onRestart: () {
          returnToTitle();
        },
      ),
    );

    // Future.delayed(Duration(milliseconds: 50), () {
    Future.delayed(Duration(milliseconds: 100), () {
      if (state != GameState.gameOver) return;
      pauseEngine();
    });

    // ハイスコア点滅停止
    hiScoreDisplay.stopBlink();

    // UFO音停止
    AudioManager().stopUfo();
    print("GAME OVER");
  }

  /// ROUND数表示
  void createRoundDisplay() {
    roundText = TextComponent(
      text: 'ROUND: $currentRound',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 10 * textScale, //20,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.topRight, // 右寄せ
    );

    // 画面下（地面ラインの少し下）
    //final groundLineDot = 224; // 既存の地面ラインと同じ
    final groundY = groundLineDot * _blockSize;

    roundText.position = Vector2(
      size.x - 10, // 右端マージン
      groundY + 2 * _blockSize, // 地面ラインの少し下
    );

    // add(roundText);
    world.add(roundText);
  }

  /// ROUND数更新
  void updateRoundDisplay() {
    roundText.text = 'ROUND: $currentRound';
  }

  /// START画面に戻る
  void returnToTitle() {
    // ラウンド初期化
    currentRound = 1;
    // 開始位置　初期化
    initialDrop = 0.0;

    // 全削除（自分以外）
    // children.where((c) => c is! CameraComponent).toList().forEach((c) => c.removeFromParent());
    // World配下を全削除
    world.children.toList().forEach((c) => c.removeFromParent());

    // タイトル表示
    startMessage = StartMessage(
      size,
      gameRef: this,
      onStart: () {
        startGame();
      },
    );
    // add(startMessage);
    world.add(startMessage);

    // フリーズ解除
    resumeEngine();
    state = GameState.title;
  }

  /// 現在のハイスコア取得
  int getHighScore() => _hiScoreBox.get('hi') ?? 0;

  /// スコア更新
  void addScore(int points) {
    score += points;
    scoreText.text = 'SCORE: $score'; // 更新

    // ハイスコアを更新する場合
    if (score > getHighScore()) {
      _hiScoreBox.put('hi', score); // Hive に保存
      // hiScoreText.text = 'HI $score'; // 表示も更新
      hiScoreDisplay.onHiScoreUpdated(score);
    }
  }

  /// ゲーム更新処理
  @override
  void update(double dt) {
    super.update(dt);

    // ゲーム中以外は処理しない
    if (state != GameState.playing) return;

    // プレーヤーがマウントされてる場合のみ処理
    // debugPrint('player isMounted=${player.isMounted}');
    if (player.isMounted) {
      // プレイヤー移動処理
      if (input.left && !input.right) {
        player.moveLeft(dt);
      } else if (input.right && !input.left) {
        player.moveRight(dt);
      }

      // プレイヤー射出処理
      if (input.fire) {
        player.shoot(this); // クールタイム付き
      }
    }

    //敵の射出処理
    _enemyShootTimer += dt;
    if (_enemyShootTimer >= _enemyShootInterval) {
      _enemyShootTimer = 0.0;

      // 画面上の敵弾をカウント
      // final currentEnemyBullets = children.whereType<EnemyBullet>().length;
      final currentEnemyBullets = world.children.whereType<EnemyBullet>().length;
      if (currentEnemyBullets >= 3) return;

      // 下列の敵だけを取得
      final bottomEnemies = _getBottomRowEnemies();
      if (bottomEnemies.isEmpty) return;

      // ランダムで1体選んで撃たせる
      final shooter = bottomEnemies[Random().nextInt(bottomEnemies.length)];

      // 名古屋撃ち判定用
      final double nagoyaZone = 2 * _blockSize; // 2ドット許容

      // 敵とプレイヤーのY位置
      final enemyBottom = shooter.position.y + shooter.height;
      final playerTop = player.position.y;

      // 敵とプレイヤーのX範囲
      final enemyLeft = shooter.position.x;
      final enemyRight = shooter.position.x + shooter.width;
      final playerLeft = player.position.x;
      final playerRight = player.position.x + player.width;

      // X軸判定：横方向が少しでも重なっているか（名古屋撃ち用）
      final isAbovePlayerX = enemyRight > playerLeft && enemyLeft < playerRight;

      // Y軸判定：プレイヤー直上 2ドット以内
      final double diff = playerTop - enemyBottom;
      final isNagoyaZone = diff > 0 && diff <= nagoyaZone;

      // 名古屋撃ち判定
      if (isAbovePlayerX && isNagoyaZone) {
        print("NO shoot 名古屋撃ち再現");
        return; // 直上では撃たない
      }

      // 発射
      shooter.shoot();
    }
  }

  /// 画面上の下列の敵を取得
  List<Enemy> _getBottomRowEnemies() {
    // final allEnemies = children.whereType<Enemy>().toList();
    final allEnemies = world.children.whereType<Enemy>().toList();
    // Map<double, Enemy> bottomEnemiesMap = {};
    Map<int, Enemy> bottomEnemiesMap = {};

    for (var enemy in allEnemies) {
      // final columnX = enemy.position.x;
      final columnKey = (enemy.position.x / blockSize).round();
      // 同じ列の敵がいれば、Y が最大（最下）を残す
      // if (!bottomEnemiesMap.containsKey(columnX) ||
      //     enemy.position.y > bottomEnemiesMap[columnX]!.position.y) {
      //   bottomEnemiesMap[columnX] = enemy;
      // }
      if (!bottomEnemiesMap.containsKey(columnKey) || enemy.position.y > bottomEnemiesMap[columnKey]!.position.y) {
        bottomEnemiesMap[columnKey] = enemy;
      }
    }

    return bottomEnemiesMap.values.toList();
  }

  void addTouchControls() {
    // 下の余白やボタンサイズを blockSize に応じて計算
    final bottomMargin = 2 * _blockSize; // ブロック2個分の余白
    final buttonWidth = 68 * _blockSize; // 幅40ブロック分
    final buttonHeight = 12 * _blockSize; // 高さ12ブロック分
    final buttonSpacing = 4 * _blockSize; // 左右ボタンの間隔
    final sideMargin = 2 * _blockSize; // 左右端からのマージン
    final y = size.y - buttonHeight / 2 - bottomMargin; // ボタン中心位置

    // 左
    world.add(
      // add(
      TouchButton(
        // position: Vector2(buttonWidth / 2 + 20, y),
        position: Vector2(buttonWidth / 2 + sideMargin, y),
        size: Vector2(buttonWidth, buttonHeight),
        type: ButtonType.left,
        // color: Colors.amber,
        // borderColor: Colors.deepOrange,
        color: Colors.cyanAccent,
        borderColor: Colors.blue,
        onDown: () => input.left = true,
        onUp: () => input.left = false,
      ),
    );

    // 右
    world.add(
      // add(
      TouchButton(
        // position: Vector2(buttonWidth * 1.5 + 20 + buttonSpacing, y),
        position: Vector2(buttonWidth * 1.5 + sideMargin + buttonSpacing, y),
        size: Vector2(buttonWidth, buttonHeight),
        type: ButtonType.right,
        // color: Colors.amber,
        // borderColor: Colors.deepOrange,
        color: Colors.cyanAccent,
        borderColor: Colors.blue,
        onDown: () => input.right = true,
        onUp: () => input.right = false,
      ),
    );

    // 発射
    world.add(
      // add(
      TouchButton(
        // position: Vector2(size.x - buttonWidth / 2 - 20, y), // 右端からマージン
        position: Vector2(size.x - buttonWidth / 2 - sideMargin, y),
        size: Vector2(buttonWidth, buttonHeight),
        type: ButtonType.fire,
        // color: Colors.orange,
        // borderColor: Colors.deepOrange,
        color: Colors.pinkAccent,
        borderColor: Colors.purple,
        onDown: () => input.fire = true,
        onUp: () => input.fire = false,
      ),
    );
  }

  void addVolumeSlider() {}
}

/// GAME OVER画面
class GameOverMessage extends PositionComponent with TapCallbacks {
  final VoidCallback onRestart;
  final InvaderGame gameRef;
  late TextComponent _text;
  // late Timer _blinkTimer;
  // bool _visible = true;

  GameOverMessage(Vector2 gameSize, {required this.onRestart, required this.gameRef})
    : super(
        position: Vector2.zero(),
        size: gameSize, // 画面全体をタップ判定に
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _text = TextComponent(
      text: 'GAME OVER\nPress to Restart',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.red,
          fontSize: 12 * gameRef.textScale, //48,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 50),
    );

    add(_text); //TODO:   world使えない
  }

  @override
  void onTapDown(TapDownEvent event) {
    onRestart();
    removeFromParent(); // 忘れず消す
  }
}

/// START画面
class StartMessage extends PositionComponent with TapCallbacks {
  final VoidCallback onStart;
  late TextComponent _text;
  late Timer _blinkTimer;
  bool _visible = true;
  final InvaderGame gameRef;

  StartMessage(Vector2 gameSize, {required this.onStart, required this.gameRef})
    : super(
        position: Vector2.zero(),
        size: gameSize, // フルスクリーンタップ判定
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _text = TextComponent(
      text: 'PRESS ENTER TO START',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 11 * gameRef.textScale, //32,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2, // 親の中央
    );

    add(_text); //TODO:   world使えない

    // 点滅タイマー
    _blinkTimer = Timer(
      0.5,
      repeat: true,
      onTick: () {
        _visible = !_visible;
        _text.text = _visible ? 'PRESS ENTER TO START' : '';
      },
    );
    _blinkTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _blinkTimer.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onStart();
  }
}

/// ボタンの種類
enum ButtonType { left, right, fire }

/// タッチ操作用ボタンコンポーネント
class TouchButton extends PositionComponent with TapCallbacks, DragCallbacks {
  final VoidCallback onDown;
  final VoidCallback onUp;

  final Color color;
  final Color borderColor;
  final ButtonType type;

  bool _pressed = false;

  late final Paint _bgPaint = Paint();
  late final Paint _borderPaint = Paint();

  TouchButton({
    required this.onDown,
    required this.onUp,
    required Vector2 position,
    required Vector2 size,
    required this.type, // ← 左右／発射を指定
    required this.color,
    required this.borderColor,
  }) {
    this.position = position;
    this.size = size;
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    // レトロフューチャーな角丸（ボタンの高さの20%を半径にする）
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(size.y * 0.2));

    // 1. ボタンの背景（押されている時は少し暗く＆沈み込むように）
    final bgAlpha = _pressed ? 0.7 : 0.9;
    _bgPaint.color = color.withValues(alpha: bgAlpha);
    canvas.drawRRect(rRect, _bgPaint);

    // 2. 内部のハイライト演出（上半分に薄い光を乗せて立体感を出す）
    if (!_pressed) {
      final highlightRect = Rect.fromLTWH(2, 2, size.x - 4, size.y * 0.4);
      final highlightRRect = RRect.fromRectAndRadius(highlightRect, Radius.circular(size.y * 0.15));
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(highlightRRect, highlightPaint);
    }

    // 3. 2重の枠線（外枠：深みのある色、内側のアクセント枠：明るい色）
    _borderPaint
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _pressed ? 2.0 : 3.5;
    canvas.drawRRect(rRect, _borderPaint);

    // 内側の細いエッジライン
    final innerRect = rect.deflate(3);
    final innerRRect = RRect.fromRectAndRadius(innerRect, Radius.circular(size.y * 0.17));
    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(innerRRect, innerBorderPaint);

    // 4. アイコン描画
    switch (type) {
      case ButtonType.left:
        _drawArrow(canvas, left: true);
        break;
      case ButtonType.right:
        _drawArrow(canvas, left: false);
        break;
      case ButtonType.fire:
        _drawFireIcon(canvas);
        break;
    }
  }

  /// カッコいいシャープな矢印描画
  void _drawArrow(Canvas canvas, {required bool left}) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // 押されている時は矢印も少し動く（押し込み感）
    final offsetY = _pressed ? 2.0 : 0.0;
    final centerY = (size.y / 2) + offsetY;

    final arrowWidth = size.x * 0.22;
    final arrowHeight = size.y * 0.45;
    final centerX = size.x / 2;

    final path = Path();
    if (left) {
      path.moveTo(centerX + arrowWidth / 2, centerY - arrowHeight / 2);
      path.lineTo(centerX - arrowWidth / 2, centerY);
      path.lineTo(centerX + arrowWidth / 2, centerY + arrowHeight / 2);
    } else {
      path.moveTo(centerX - arrowWidth / 2, centerY - arrowHeight / 2);
      path.lineTo(centerX + arrowWidth / 2, centerY);
      path.lineTo(centerX - arrowWidth / 2, centerY + arrowHeight / 2);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  /// 近未来的な発射（ファイア）アイコン
  void _drawFireIcon(Canvas canvas) {
    final offsetY = _pressed ? 2.0 : 0.0;
    final center = Offset(size.x / 2, (size.y / 2) + offsetY);
    final radius = (size.x < size.y ? size.x : size.y) * 0.32;

    // 外側のリング
    final ringPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final ringBorder = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius, ringBorder);

    // 中央のレーザーコア風ドット（中心が光っているような二重構造）
    final coreOuterPaint = Paint()
      ..color = Colors.deepOrange.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, coreOuterPaint);

    final coreInnerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.3, coreInnerPaint);
  }

  /*
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 背景
    _bgPaint.color = _pressed ? color.withValues(alpha: 0.9) : color;
    canvas.drawRect(rect, _bgPaint);

    // 枠線
    _borderPaint
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(rect, _borderPaint);

    // 矢印／アイコン描画
    switch (type) {
      case ButtonType.left:
        _drawArrow(canvas, left: true);
        // _drawArrowIOS(canvas, left: true);
        break;
      case ButtonType.right:
        _drawArrow(canvas, left: false);
        break;
      case ButtonType.fire:
        _drawFireIcon(canvas);
        break;
    }
  }

  /// 矢印描画
  void _drawArrow(Canvas canvas, {required bool left}) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final centerY = size.y / 2;
    final arrowWidth = size.x * 0.25;
    final arrowHeight = size.y * 0.4;

    final centerX = size.x / 2;

    final path = Path();

    if (left) {
      path.moveTo(centerX + arrowWidth / 2, centerY - arrowHeight / 2);
      path.lineTo(centerX - arrowWidth / 2, centerY);
      path.lineTo(centerX + arrowWidth / 2, centerY + arrowHeight / 2);
    } else {
      path.moveTo(centerX - arrowWidth / 2, centerY - arrowHeight / 2);
      path.lineTo(centerX + arrowWidth / 2, centerY);
      path.lineTo(centerX - arrowWidth / 2, centerY + arrowHeight / 2);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  /// 発射アイコン
  void _drawFireIcon(Canvas canvas, {bool pressed = false}) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (size.x < size.y ? size.x : size.y) * 0.35;

    // 背景
    final bgPaint = Paint()
      ..color = pressed ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // 枠
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 中央の発射ドット
    final dotPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.35, dotPaint);
  }
*/
  @override
  void onTapDown(TapDownEvent event) {
    if (_pressed) return;
    _pressed = true;
    onDown();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _release();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    // Drag に移行するので何もしない
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_pressed) return; // ★重要
    _pressed = true;
    onDown();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _release();
  }

  void _release() {
    if (!_pressed) return;
    _pressed = false;
    onUp();
  }
}
