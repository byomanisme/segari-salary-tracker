import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class BlockBlastAudio {
  static final BlockBlastAudio instance = BlockBlastAudio._internal();
  BlockBlastAudio._internal();

  bool isMuted = false;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _blastPlayer = AudioPlayer();
  final AudioPlayer _chimePlayer = AudioPlayer();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _blastPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _chimePlayer.setPlayerMode(PlayerMode.lowLatency);
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing BlockBlastAudio: $e');
    }
  }

  void playPlace() {
    if (isMuted) return;
    try {
      _sfxPlayer.stop();
      _sfxPlayer.play(AssetSource('sounds/place.wav'));
    } catch (e) {
      debugPrint('Audio playPlace error: $e');
    }
  }

  void playClear(int combo) {
    if (isMuted) return;
    try {
      final soundFile = combo >= 5
          ? 'sounds/combo_mega.wav'
          : 'sounds/clear_${combo.clamp(1, 6)}.wav';
      _blastPlayer.stop();
      _blastPlayer.play(AssetSource(soundFile));
    } catch (e) {
      debugPrint('Audio playClear error: $e');
    }
  }

  void playMascot() {
    if (isMuted) return;
    try {
      _chimePlayer.stop();
      _chimePlayer.play(AssetSource('sounds/mascot_pop.wav'));
    } catch (e) {
      debugPrint('Audio playMascot error: $e');
    }
  }

  void playLevelUp() {
    if (isMuted) return;
    try {
      _chimePlayer.stop();
      _chimePlayer.play(AssetSource('sounds/level_up.wav'));
    } catch (e) {
      debugPrint('Audio playLevelUp error: $e');
    }
  }

  void playGameOver() {
    if (isMuted) return;
    try {
      _chimePlayer.stop();
      _chimePlayer.play(AssetSource('sounds/game_over.wav'));
    } catch (e) {
      debugPrint('Audio playGameOver error: $e');
    }
  }

  void playRevive() {
    if (isMuted) return;
    try {
      _chimePlayer.stop();
      _chimePlayer.play(AssetSource('sounds/revive.wav'));
    } catch (e) {
      debugPrint('Audio playRevive error: $e');
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _blastPlayer.dispose();
    _chimePlayer.dispose();
  }
}
