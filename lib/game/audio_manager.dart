import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

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
  late final List<List<AudioPlayer>> _invaderPlayers;

  int _stepIndex = 0;

  // bool _ufoPlaying = false;

  final List<String> _invaderSteps = ['sounds/80.wav', 'sounds/120.wav', 'sounds/150.wav', 'sounds/120.wav'];

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
  int _poolIndex = 0;

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
    _shootPlayer = AudioPlayer();
    _shootPlayer.setVolume(1.0);
    // ★ 再生完了後に音源を破棄しないように設定
    await _shootPlayer.setReleaseMode(ReleaseMode.stop);
    await _shootPlayer.setSource(AssetSource('sounds/shoot.mp3'));

    _explosionPlayer = AudioPlayer();
    _explosionPlayer.setVolume(1.0); // ボリューム調整
    await _explosionPlayer.setReleaseMode(ReleaseMode.stop);
    await _explosionPlayer.setSource(AssetSource('sounds/explosion.mp3'));

    _hitPlayer = AudioPlayer();
    _hitPlayer.setVolume(1.0);
    await _hitPlayer.setReleaseMode(ReleaseMode.stop);
    await _hitPlayer.setSource(AssetSource('sounds/hit.mp3'));

    _hitUfoPlayer = AudioPlayer();
    _hitUfoPlayer.setVolume(1.0);
    await _hitPlayer.setReleaseMode(ReleaseMode.stop);
    await _hitPlayer.setSource(AssetSource('sounds/hit_ufo.mp3'));

    _ufo4loopPlayer = AudioPlayer();
    _ufo4loopPlayer.setVolume(1.0);
    _ufo4loopPlayer.setReleaseMode(ReleaseMode.loop); // ループ再生
    // _ufo4loopPlayer.setSource(AssetSource('sounds/ufo.mp3'));

    // 進軍効果音
    // _invaderPlayers = [];
    // for (final path in _invaderSteps) {
    //   final p = AudioPlayer();
    //   await p.setReleaseMode(ReleaseMode.stop);
    //   await p.setSource(AssetSource(path));
    //   p.setVolume(0.8);

    //   _invaderPlayers.add(p);
    // }

    // ==========================
    // 進軍効果音
    // 4種類 × 2プレイヤー
    // ==========================
    _invaderPlayers = [];

    for (final path in _invaderSteps) {
      final list = <AudioPlayer>[];

      for (int i = 0; i < 2; i++) {
        final p = AudioPlayer();

        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(path));
        p.setVolume(0.8);

        list.add(p);
      }

      _invaderPlayers.add(list);
    }

    // _invaderStepPlayer = AudioPlayer();
    // _invaderStepPlayer.setVolume(0.8);
    // // ★ 再生完了後に音源を破棄しないように設定
    // await _invaderStepPlayer.setReleaseMode(ReleaseMode.stop);
    // await _invaderStepPlayer.setSource(AssetSource('sounds/shoot.mp3'));
  }

  void setMasterVolume(double value) {
    masterVolume = value;

    _shootPlayer.setVolume(value);
    _explosionPlayer.setVolume(value);
    _hitPlayer.setVolume(value);
    _hitUfoPlayer.setVolume(value);
    _ufo4loopPlayer.setVolume(value);
    // _invaderStepPlayer.setVolume(value);
    // for (final player in _invaderPlayers) {
    //   player.setVolume(value);
    // }
    for (final list in _invaderPlayers) {
      for (final player in list) {
        player.setVolume(value);
      }
    }
  }

  // 進軍効果音再生
  Future<void> playInvaderStep() async {
    final players = _invaderPlayers[_stepIndex];

    final player = players[_poolIndex];

    unawaited(
      player.seek(Duration.zero).then((_) => player.resume()).catchError((e) {
        debugPrint(e.toString());
      }),
    );

    // 次の音
    _stepIndex = (_stepIndex + 1) % _invaderPlayers.length;

    // 同じ音は次回は別プレイヤー
    _poolIndex ^= 1;
    /*
    final player = _invaderPlayers[_stepIndex];
    debugPrint("----- playInvaderStep -----      ${player.state.toString()}  ");
    unawaited(player.seek(Duration.zero).then((_) => player.resume()).catchError((_) {}));

    _stepIndex = (_stepIndex + 1) % _invaderPlayers.length;
    */
  }

  // void playInvaderStep() {
  //   final path = _invaderSteps[_stepIndex];

  //   // _invaderStepPlayer.play(AssetSource(path));

  //   unawaited(_invaderStepPlayer.seek(Duration.zero).then((_) => _invaderStepPlayer.resume()).catchError((e) {})); // サウンドを再生

  //   // ★ 60ms で強制停止（重要）
  //   Future.delayed(const Duration(milliseconds: 100), () {
  //     // _invaderStepPlayer.stop();
  //   });

  //   _stepIndex = (_stepIndex + 1) % 4;
  // }

  /*
  void playInvaderStep() {
    final path = _invaderSteps[_stepIndex];
    playSE(path, volume: 0.8);

    _stepIndex = (_stepIndex + 1) % _invaderSteps.length;
  }
*/
  /*
  void playInvaderStepWithEnemies(int enemyCount) {
    final pitch = getPitchIndex(enemyCount);

    // 4拍子ローテーション（本家感）
    final path = _invaderSteps[(pitch + _stepIndex) % _invaderSteps.length];

    playSE(path, volume: 0.8);

    _stepIndex = (_stepIndex + 1) % 4;
  }
*/
  void playShoot() {
    // _shootPlayer.play('shoot.mp3');
    // unawaited(
    //   _shootPlayer.play(AssetSource('sounds/shoot.mp3')).catchError((e) {
    //     // AbortError は無視
    //   }),
    // ); // サウンドを再生

    unawaited(_shootPlayer.seek(Duration.zero).then((_) => _shootPlayer.resume()).catchError((e) {})); // サウンドを再生

    // playSE('sounds/shoot.mp3');
  }

  void playExplosion() {
    // unawaited(
    //   _explosionPlayer.play(AssetSource('sounds/explosion.mp3')).catchError((e) {
    //     // AbortError は無視
    //   }),
    // ); // サウンドを再生
    unawaited(_explosionPlayer.seek(Duration.zero).then((_) => _explosionPlayer.resume()).catchError((e) {})); // サウンドを再生
    // playSE('sounds/explosion.mp3');
  }

  void enemyHit() {
    // unawaited(
    //   _hitPlayer.play(AssetSource('sounds/hit.mp3')).catchError((e) {
    //     // AbortError は無視
    //   }),
    // ); // サウンドを再生
    unawaited(_hitPlayer.seek(Duration.zero).then((_) => _hitPlayer.resume()).catchError((e) {})); // サウンドを再生
    // playSE('sounds/hit.mp3');
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
    // if (_ufoPlaying) return;
    // _ufoPlaying = true;
    _ufo4loopPlayer.play(AssetSource('sounds/ufo.mp3')).catchError((e) {
      // AbortError は無視
    }); // サウンドを再生
  }

  void stopUfo() {
    // _ufoPlaying = false;
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
  int getPitchIndex(int enemyCount) {
    if (enemyCount > 40) return 0; // 低音
    if (enemyCount > 25) return 1;
    if (enemyCount > 10) return 2;
    return 3; // 高音
  }
}
