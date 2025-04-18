import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:froggydoro/screens/settings_screen.dart';

class AudioManager {
  static AudioManager? instance;
  final AudioPlayer _audioPlayer;

  factory AudioManager({AudioPlayer? player}) {
    instance ??= AudioManager.internal(player ?? AudioPlayer());
    return instance!;
  }

  AudioManager.internal(this._audioPlayer);

  @visibleForTesting
  static void overrideInstance(AudioManager testInstance) {
    instance = testInstance;
  }

  String currentSong = "None";

  Future<void> playMusic([String? newSong]) async {
    newSong ??= await SettingsScreen.getAmbience();
    if (newSong == "None" || currentSong == "None") {
      return;
    }
    currentSong = newSong.toLowerCase();

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.0);

    await _audioPlayer.play(AssetSource("$currentSong.mp3"));
    fadeInMusic();
  }

  Future<void> fadeInMusic({double duration = 3.0}) async {
    double volume = 0.0;
    int steps = 10;
    double increment = 1.0 / steps;

    for (int i = 0; i < steps; i++) {
      volume += increment;
      await _audioPlayer.setVolume(volume);
      await Future.delayed(Duration(milliseconds: (duration * 1000 ~/ steps)));
    }
  }

  Future<void> fadeOutMusic({double duration = 3.0}) async {
    double volume = 1.0;
    int steps = 10;
    double decrement = 1.0 / steps;

    for (int i = 0; i < steps; i++) {
      volume -= decrement;
      await _audioPlayer.setVolume(volume);
      await Future.delayed(Duration(milliseconds: (duration * 1000 ~/ steps)));
    }

    await _audioPlayer.stop();
  }

  Future<void> stopMusic() async {
    await _audioPlayer.stop();
  }

  Future<void> pauseMusic() async {
    await _audioPlayer.pause();
  }

  Future<void> resumeMusic() async {
    await _audioPlayer.resume();
  }
}
