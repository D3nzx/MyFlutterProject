// lib/services/audio_player_service.dart
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer player = AudioPlayer();

  List<Map<String, dynamic>> _songs = [];
  final ValueNotifier<int?> currentIndexNotifier = ValueNotifier<int?>(null);

  // 0: Off, 1: Loop Song, 2: Loop All, 3: Shuffle All
  final ValueNotifier<int> playModeNotifier = ValueNotifier<int>(0);

  int get playMode => playModeNotifier.value;
  set playMode(int mode) {
    playModeNotifier.value = mode;
  }

  Future<void> setPlayMode(int mode) async {
    playMode = mode;
    switch (mode) {
      case 1: // Loop Song
        await player.setLoopMode(LoopMode.one);
        await player.setShuffleModeEnabled(false);
        break;
      case 2: // Loop All
        await player.setLoopMode(LoopMode.all);
        await player.setShuffleModeEnabled(false);
        break;
      case 3: // Shuffle All
        await player.setLoopMode(LoopMode.all);
        await player.setShuffleModeEnabled(true);
        await player.shuffle();
        break;
      default: // Off
        await player.setLoopMode(LoopMode.off);
        await player.setShuffleModeEnabled(false);
    }
  }

  void setSongs(List<Map<String, dynamic>> songs) {
    _songs = songs;
  }

  List<Map<String, dynamic>> get songs => _songs;

  Future<void> playSongAt(int index, String url) async {
    // Prevent reloading if already playing this song
    if (currentIndexNotifier.value == index &&
        player.audioSource != null &&
        player.playing) {
      return;
    }
    currentIndexNotifier.value = index;
    await player.setUrl(url);
    await player.play();
  }

  Future<void> play(String url) async {
    await player.setUrl(url);
    await player.play();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> playNext() async {
    if (currentIndexNotifier.value != null &&
        currentIndexNotifier.value! < _songs.length - 1) {
      final nextIndex = currentIndexNotifier.value! + 1;
      final nextSong = _songs[nextIndex];
      await playSongAt(nextIndex, nextSong['audio_path']);
    }
  }

  Future<void> playPrevious() async {
    if (currentIndexNotifier.value != null && currentIndexNotifier.value! > 0) {
      final prevIndex = currentIndexNotifier.value! - 1;
      final prevSong = _songs[prevIndex];
      await playSongAt(prevIndex, prevSong['audio_path']);
    }
  }
}
