import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BlockBlastAudio {
  static final BlockBlastAudio instance = BlockBlastAudio._internal();
  BlockBlastAudio._internal();

  bool isMuted = false;

  // Pool of 8 concurrent AudioPlayers to guarantee zero dropped sounds and polyphony
  static const int _poolSize = 8;
  final List<AudioPlayer> _pool = List.generate(_poolSize, (_) => AudioPlayer());
  int _poolIndex = 0;

  final Map<String, Uint8List> _soundCache = {};
  bool _initialized = false;
  int _placeVariantIndex = 0;

  static const List<String> _soundNames = [
    'place_1',
    'place_2',
    'place_3',
    'place_4',
    'pickup',
    'invalid',
    'caterpillar_step',
    'snake_step',
    'mascot_spawn',
    'mascot_pop',
    'clear_1',
    'clear_2',
    'clear_3',
    'clear_4',
    'clear_5',
    'clear_6',
    'combo_mega',
    'level_up',
    'game_over',
    'revive',
  ];

  Future<void> init() async {
    if (_initialized) return;
    try {
      // 1. Configure audio context for games
      final gameContext = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      );

      for (final player in _pool) {
        try {
          await player.setAudioContext(gameContext);
          await player.setReleaseMode(ReleaseMode.stop);
        } catch (_) {}
      }

      // 2. Preload all WAV audio files into RAM for instantaneous, 100% reliable playback
      for (final name in _soundNames) {
        try {
          final data = await rootBundle.load('assets/sounds/$name.wav');
          _soundCache[name] = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('Audio asset load warning for $name: $e');
        }
      }

      _initialized = true;
      debugPrint('BlockBlastAudio initialized with ${_soundCache.length} cached sounds.');
    } catch (e) {
      debugPrint('Error initializing BlockBlastAudio: $e');
    }
  }

  void _play(String soundName, {double volume = 1.0}) {
    if (isMuted) return;
    try {
      final bytes = _soundCache[soundName];
      final player = _pool[_poolIndex % _poolSize];
      _poolIndex++;

      if (bytes != null) {
        player.setVolume(volume);
        player.play(BytesSource(bytes));
      } else {
        // Fallback to asset source if not yet in byte cache
        player.setVolume(volume);
        player.play(AssetSource('sounds/$soundName.wav'));
      }
    } catch (e) {
      debugPrint('Audio _play error for $soundName: $e');
    }
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
      _play('snake_step', volume: 0.8);
    } else {
      _play('caterpillar_step', volume: 0.85);
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
    for (final player in _pool) {
      try {
        player.dispose();
      } catch (_) {}
    }
  }
}
