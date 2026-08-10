import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  // クラスのインスタンスを保持するプライベートな静的変数
  static final AudioManager _instance = AudioManager._internal();

  // 個別の AudioPlayer インスタンス
  late AudioPlayer _shootPlayer;
  late AudioPlayer _explosionPlayer;
  late AudioPlayer _hitPlayer;
  late AudioPlayer _hitUfoPlayer;
  late AudioPlayer _ufo4loopPlayer;
  // 進軍効果音用
  // late AudioPlayer _invaderStepPlayer;
  // late final List<AudioPlayer> _invaderPlayers;
  // late final List<List<AudioPlayer>> _invaderPlayers;
  late final List<AudioPool> _invaderPools = [];

  int _stepIndex = 0;

  // bool _ufoPlaying = false;

  // final List<String> _invaderSteps = ['sounds/80.mp3', 'sounds/120.mp3', 'sounds/150.mp3', 'sounds/mp3.wav'];
  // AudioPool はデフォルト　assets\audio\　らしい
  final List<String> _invaderSteps = ['80.wav', '120.wav', '150.wav', '120.wav'];

  double masterVolume = 1.0;

  // // 進軍音（4種類×2 = 8プレイヤー）
  // late final List<List<AudioPlayer>> _invaderPlayers;

  // final List<String> _invaderSteps = [
  //   'sounds/80.wav',
  //   'sounds/120.wav',
  //   'sounds/150.wav',
  //   'sounds/120.wav',
  // ];

  // int _stepIndex = 0;
  // int _poolIndex = 0;

  // 初期化フラグ
  bool _initialized = false;

  // シングルトンの factory コンストラクタ
  factory AudioManager() {
    return _instance;
  }

  // _internal() は シングルトン専用のコンストラクタ
  // 外部からは呼べない
  // _instance の初期化時に呼ばれる
  // 削除すると無限再帰やコンパイルエラーになるので必ず必要
  // プライベートなコンストラクタ
  AudioManager._internal();

  // 各音声ファイルをロードする
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint("AudioManager init start");

    // Android / iOSだけAudioContextを設定
    if (!kIsWeb) {
      final audioContext = AudioContext(
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
        ),
        // iOSはまだ未確認
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback, options: {AVAudioSessionOptions.mixWithOthers}),
      );

      await AudioPlayer.global.setAudioContext(audioContext);
    }

    // 1. プレイヤーのインスタンス作成
    _shootPlayer = AudioPlayer();
    await _shootPlayer.setReleaseMode(ReleaseMode.stop);
    await _shootPlayer.setVolume(1.0);

    _explosionPlayer = AudioPlayer();
    await _explosionPlayer.setReleaseMode(ReleaseMode.stop);
    _explosionPlayer.setVolume(1.0);

    _hitPlayer = AudioPlayer();
    await _hitPlayer.setReleaseMode(ReleaseMode.stop);
    _hitPlayer.setVolume(1.0);

    _hitUfoPlayer = AudioPlayer();
    await _hitUfoPlayer.setReleaseMode(ReleaseMode.stop);
    _hitUfoPlayer.setVolume(1.0);

    _ufo4loopPlayer = AudioPlayer();
    await _ufo4loopPlayer.setReleaseMode(ReleaseMode.loop);
    _ufo4loopPlayer.setVolume(1.0);

    for (final path in _invaderSteps) {
      // final pool = await FlameAudio.createPool(path.replaceFirst('sounds/', ''), minPlayers: 1, maxPlayers: 2);
      final pool = await FlameAudio.createPool(path, minPlayers: 1, maxPlayers: 2);

      _invaderPools.add(pool);
    }

    // 2. 全ファイルの読み込み（setSource）を【完全に同時に】行う（並列化）
    final loadFutures = <Future>[
      _shootPlayer.setSource(AssetSource('sounds/shoot.mp3')),
      _explosionPlayer.setSource(AssetSource('sounds/explosion.mp3')),
      _hitPlayer.setSource(AssetSource('sounds/hit.mp3')),
      _hitUfoPlayer.setSource(AssetSource('sounds/hit_ufo.mp3')),
    ];

    await Future.wait(loadFutures);
  }

  void setMasterVolume(double value) {
    masterVolume = value;

    _shootPlayer.setVolume(value);
    _explosionPlayer.setVolume(value);
    _hitPlayer.setVolume(value);
    _hitUfoPlayer.setVolume(value);
    _ufo4loopPlayer.setVolume(value);

    // for (final list in _invaderPlayers) {
    //   for (final player in list) {
    //     player.setVolume(value);
    //   }
    // }
  }

  // 進軍効果音再生
  Future<void> playInvaderStep() async {
    final pool = _invaderPools[_stepIndex];

    unawaited(
      // pool.start(volume: masterVolume).catchError((e) {
      //   debugPrint('invader step error: $e');
      // }),
      _playInvaderStep(pool),
    );

    _stepIndex = (_stepIndex + 1) % _invaderPools.length;
  }

  Future<void> _playInvaderStep(AudioPool pool) async {
    try {
      await pool.start(volume: masterVolume);
    } catch (e) {
      debugPrint('invader step error: $e');
    }
  }

  void playShoot() {
    unawaited(
      _shootPlayer.seek(Duration.zero).then((_) => _shootPlayer.resume()).catchError((e, s) {
        debugPrint("shoot error=$e");
        debugPrint("$s");
      }),
    );
  }

  void playExplosion() {
    unawaited(_explosionPlayer.seek(Duration.zero).then((_) => _explosionPlayer.resume()).catchError((e) {})); // サウンドを再生
  }

  void enemyHit() {
    unawaited(_hitPlayer.seek(Duration.zero).then((_) => _hitPlayer.resume()).catchError((e) {})); // サウンドを再生
  }

  void playHitUfo() {
    unawaited(
      _hitUfoPlayer.play(AssetSource('sounds/hit_ufo.mp3')).catchError((e) {
        // AbortError は無視
      }),
    ); // サウンドを再生
    unawaited(_hitUfoPlayer.seek(Duration.zero).then((_) => _hitUfoPlayer.resume()).catchError((e) {})); // サウンドを再生
    // playSE('sounds/hit_ufo.mp3');
  }

  void playUfo() {
    _ufo4loopPlayer.play(AssetSource('sounds/ufo.mp3')).catchError((e) {
      // AbortError は無視
    }); // サウンドを再生
  }

  void stopUfo() {
    _ufo4loopPlayer.stop();
  }

  /*
  // 各音声を再生するメソッド
  void playSE(String path, {double volume = 1.0}) {
    final p = AudioPlayer();
    p.setVolume(volume);
    p.play(AssetSource(path));
    p.onPlayerComplete.listen((_) {
      p.dispose();
    });

    for (final list in _invaderPlayers) {
      for (final p in list) {
        p.dispose();
      }
    }
  }
*/
  /*
  int getPitchIndex(int enemyCount) {
    if (enemyCount > 40) return 0; // 低音
    if (enemyCount > 25) return 1;
    if (enemyCount > 10) return 2;
    return 3; // 高音
  }
  */
}
