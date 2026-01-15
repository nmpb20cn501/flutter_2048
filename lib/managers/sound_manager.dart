import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings.dart';

class SoundManager {
  final Ref ref;
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _mergePlayer = AudioPlayer();

  SoundManager(this.ref);

  // Play move sound (khi tiles di chuyển) - simple click
  Future<void> playMove() async {
    if (!ref.read(settingsManager).isSoundEnabled) return;

    try {
      // Play a simple beep using system sound
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silent fail
    }
  }

  // Play merge sound (khi 2 tiles merge) - slightly louder
  Future<void> playMerge() async {
    if (!ref.read(settingsManager).isSoundEnabled) return;

    try {
      // Use alert sound for merge (more noticeable)
      await SystemSound.play(SystemSoundType.click);
      // Play twice for emphasis
      await Future.delayed(const Duration(milliseconds: 50));
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silent fail
    }
  }

  // Play win sound
  Future<void> playWin() async {
    if (!ref.read(settingsManager).isSoundEnabled) return;

    try {
      // Play success sound sequence
      for (int i = 0; i < 3; i++) {
        await SystemSound.play(SystemSoundType.click);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Play game over sound
  Future<void> playGameOver() async {
    if (!ref.read(settingsManager).isSoundEnabled) return;

    try {
      // Play alert for game over
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Silent fail
    }
  }

  void dispose() {
    _movePlayer.dispose();
    _mergePlayer.dispose();
  }
}

final soundManagerProvider = Provider<SoundManager>((ref) {
  return SoundManager(ref);
});
