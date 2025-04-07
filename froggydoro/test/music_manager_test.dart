import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:froggydoro/widgets/music_manager.dart';

@GenerateMocks([AudioPlayer])
import 'music_manager_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Music manager tests',() {

    late MockAudioPlayer mockPlayer;
    late AudioManager audioManager;
    setUp(() {
      mockPlayer = MockAudioPlayer();
      audioManager = AudioManager.internal(mockPlayer);
      AudioManager.overrideInstance(audioManager);
    });

    test('fadeInMusic gradually increases volume', () async {
      when(mockPlayer.setVolume(any)).thenAnswer((_) async => Future.value());
      await audioManager.fadeInMusic(duration: 1.0);

      final captured = verify(mockPlayer.setVolume(captureAny)).captured;

      expect(captured.length, 10);

      for (int i = 1; i < captured.length; i++) {
        expect(captured[i], greaterThan(captured[i - 1]),
          reason: 'Volume should increase step by step');
      }
    });

    test('playMusic does nothing if newSong is "None"', () async {
      await audioManager.playMusic("None");

      verifyNever(mockPlayer.stop());
      verifyNever(mockPlayer.play(any));
    });

    test('playMusic does nothing if _currentSong is "None"', () async {
      AudioManager.overrideInstance(AudioManager(player: mockPlayer));
      AudioManager.instance!.currentSong = "None";

      await AudioManager.instance!.playMusic("Bonfire");

      verifyNever(mockPlayer.stop());
      verifyNever(mockPlayer.play(any));
    });

    test('playMusic calls stop on the player', () async {
      AudioManager.overrideInstance(AudioManager(player: mockPlayer));
      AudioManager.instance!.currentSong = "Bonfire";

      await AudioManager.instance!.playMusic("Bonfire");

      verify(mockPlayer.stop()).called(1);
    });

    test('playMusic sets to loop on the player', () async {
      AudioManager.overrideInstance(AudioManager(player: mockPlayer));
      AudioManager.instance!.currentSong = "Bonfire";

      await AudioManager.instance!.playMusic("Bonfire");

      verify(mockPlayer.setReleaseMode(ReleaseMode.loop)).called(1);
    });

    test('playMusic sets to loop on the player', () async {
      AudioManager.overrideInstance(AudioManager(player: mockPlayer));
      AudioManager.instance!.currentSong = "Bonfire";

      await AudioManager.instance!.playMusic("Bonfire");

      verify(mockPlayer.setVolume(0.0)).called(1);
    });

    test('fadeOutMusic gradually decreases volume', () async {
      when(mockPlayer.setVolume(any)).thenAnswer((_) async => Future.value());
      await audioManager.fadeOutMusic(duration: 1.0);

      final captured = verify(mockPlayer.setVolume(captureAny)).captured;

      expect(captured.length, 10);

      for (int i = 1; i < captured.length; i++) {
        expect(captured[i], lessThan(captured[i - 1]),
          reason: 'Volume should increase step by step');
      }
    });

    test('fadeOutMusic calls stop music', () async{
      when(mockPlayer.setVolume(any)).thenAnswer((_) async => Future.value());
      when(mockPlayer.stop()).thenAnswer((_) async => Future.value());

      await audioManager.fadeOutMusic(duration: 1.0);

      verify(mockPlayer.stop()).called(1);
    });

    test('stopMusic calls stop for player', () async {
      await audioManager.stopMusic();

      verify(mockPlayer.stop()).called(1);
    });

    
    test('pauseMusic calls pause for player', () async {
      await audioManager.pauseMusic();

      verify(mockPlayer.pause()).called(1);
    });

    test('resumeMusic calls resume for player', () async {
      await audioManager.resumeMusic();

      verify(mockPlayer.resume()).called(1);
    });
  });
}

