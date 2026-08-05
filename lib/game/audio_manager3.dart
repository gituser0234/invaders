import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  // Singleton
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // 効果音（SE）
  static const String _shoot = 'sounds/shoot.ogg';
  static const String _explosion = 'sounds/explosion.ogg';
  static const String _hit = 'sounds/hit.ogg';
  static const String _hitUfo = 'sounds/hit_ufo.ogg';

  // ループ音（BGM扱い）
  static const String _ufo = 'sounds/ufo.ogg';

  /// 初期化（起動時に1回）
  Future<void> init() async {
    await FlameAudio.audioCache.loadAll([
      _shoot,
      _explosion,
      _hit,
      _hitUfo,
      _ufo,
    ]);
  }

  /// ===== 効果音 =====
  void playShoot() {
    FlameAudio.play(_shoot, volume: 1.0);
  }

  void playExplosion() {
    FlameAudio.play(_explosion, volume: 1.0);
  }

  void playHit() {
    FlameAudio.play(_hit, volume: 1.0);
  }

  void playHitUfo() {
    FlameAudio.play(_hitUfo, volume: 1.0);
  }

  /// ===== UFO ループ音（BGM）=====
  void playUfo() {
    FlameAudio.bgm.play(
      _ufo,
      volume: 1.0,
    );
  }

  void stopUfo() {
    FlameAudio.bgm.stop();
  }

  /// 念のため全部止める
  void stopAll() {
    FlameAudio.bgm.stop();
  }
}
