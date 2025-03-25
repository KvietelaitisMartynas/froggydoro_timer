import 'package:audioplayers/audioplayers.dart';
import 'package:froggydoro/screens/settings_screen.dart';

class AudioManager{
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  late final AudioPlayer _audioPlayer;
  String _currentSong = "bonfire";

  AudioManager._internal() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> playMusic([String? newSong]) async {
    newSong ??= await SettingsScreen.getAmbience();
    if(newSong == "None" || _currentSong == "None"){
      return; 
    }
    _currentSong = await newSong.toLowerCase();

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.0);

    await _audioPlayer.play(AssetSource("$_currentSong.mp3"));
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
