import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BlockBlastAudio {
  static final BlockBlastAudio instance = BlockBlastAudio._internal();
  BlockBlastAudio._internal();

  static const MethodChannel _nativeChannel =
      MethodChannel('com.segari.salarytracker/soundpool');

  bool isMuted = false;
  int _placeVariantIndex = 0;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _nativeChannel.invokeMethod('init');
      }
      _initialized = true;
      debugPrint('BlockBlastAudio native SoundPool initialized successfully.');
    } catch (e) {
      debugPrint('BlockBlastAudio native init error: $e');
    }
  }

  void _play(String soundName, {double volume = 1.0}) {
    if (isMuted) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _nativeChannel.invokeMethod('play', {
          'name': soundName,
          'volume': volume,
        });
      }
    } catch (e) {
      debugPrint('BlockBlastAudio _play error for $soundName: $e');
    }
  }

  void setMuted(bool muted) {
    isMuted = muted;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _nativeChannel.invokeMethod('setMuted', {'muted': muted});
      }
    } catch (_) {}
  }

  /// Varied tactile block placement sounds (cycles 1 to 4)
  void playPlace({int? variant}) {
    final idx = variant ?? ((_placeVariantIndex++ % 4) + 1);
    _play('place_$idx');
  }

  /// When picking up / touching a block to drag
  void playPickup() {
    _play('pickup', volume: 0.7);
  }

  /// When dropping on an invalid cell or releasing outside
  void playInvalid() {
    _play('invalid', volume: 0.6);
  }

  /// Unique step sounds when the mascot enters an empty board cell
  void playMascotStep(String skinId) {
    if (skinId == 'snake') {
      _play('snake_step', volume: 0.85);
    } else {
      _play('caterpillar_step', volume: 0.9);
    }
  }

  /// Gentle alert chime when the cameo mascot first spawns on the board
  void playMascotSpawn() {
    _play('mascot_spawn', volume: 0.75);
  }

  /// Line clear chimes (Do-Re-Mi-Fa-Sol-La marimba or Mega Combo arpeggio)
  void playClear(int combo) {
    if (combo >= 5) {
      _play('combo_mega');
    } else {
      final clamped = combo.clamp(1, 6);
      _play('clear_$clamped');
    }
  }

  /// Reward sound when tapping the cameo mascot
  void playMascot() {
    _play('mascot_pop');
  }

  /// Celebratory fanfare on level up
  void playLevelUp() {
    _play('level_up');
  }

  /// Melancholic gentle marimba on game over
  void playGameOver() {
    _play('game_over');
  }

  /// Cosmic surge on revive
  void playRevive() {
    _play('revive');
  }

  void dispose() {
    // SoundPool lifecycle is tied to Android Activity
  }
}
