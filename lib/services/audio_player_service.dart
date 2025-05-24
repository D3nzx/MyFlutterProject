import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer player = AudioPlayer();

  List<Map<String, dynamic>> _songs = [];
  final ValueNotifier<int?> currentIndexNotifier = ValueNotifier<int?>(null);


  final ValueNotifier<int> playModeNotifier = ValueNotifier<int>(0);

  ConcatenatingAudioSource? _playlistSource;


  List<int> _shuffleOrder = [];
  int _shufflePosition = 0;

  StreamSubscription? _shuffleAutoNextSub;

  int get playMode => playModeNotifier.value;
  set playMode(int mode) {
    playModeNotifier.value = mode;
  }

  Future<void> setPlayMode(int mode) async {
    playMode = mode;
    switch (mode) {
      case 1: // Repeat One
        await player.setLoopMode(LoopMode.one);
        await player.setShuffleModeEnabled(false);
        _cancelShuffleAutoNext();
        break;
      case 2: // Repeat All
        await player.setLoopMode(LoopMode.all);
        await player.setShuffleModeEnabled(false);
        _cancelShuffleAutoNext();
        break;
      case 3: // Shuffle All
        await player.setLoopMode(LoopMode.off);
        await player.setShuffleModeEnabled(false);

        if (_shuffleOrder.isEmpty || _shuffleOrder.length != _songs.length) {
          _generateShuffleOrder(currentIndex: player.currentIndex ?? 0);
        }
        _setupShuffleAutoNext();
        break;
      default: // Off
        await player.setLoopMode(LoopMode.off);
        await player.setShuffleModeEnabled(false);
        _cancelShuffleAutoNext();
    }
  }

  void setSongs(List<Map<String, dynamic>> songs) {
    _songs = songs;
    _playlistSource = ConcatenatingAudioSource(
      children: songs.map((song) => AudioSource.uri(Uri.parse(song['audioUrl'] ?? song['audio_path']))).toList(),
    );
    setPlayMode(playMode);
  }

  List<Map<String, dynamic>> get songs => _songs;

  Future<void> playSongAt(int index, String url) async {
    if (_playlistSource == null || player.audioSource != _playlistSource) {
      await player.setAudioSource(_playlistSource!, initialIndex: index);
      await setPlayMode(playMode);
    } else {
      await player.seek(Duration.zero, index: index);
    }
    currentIndexNotifier.value = index;
    if (playMode == 3) {

      if (_shuffleOrder.isEmpty || !_shuffleOrder.contains(index) || _shuffleOrder.length != _songs.length) {
        _generateShuffleOrder(currentIndex: index);
      } else {

        _shufflePosition = _shuffleOrder.indexOf(index);
      }
    }
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

  // Generate a new shuffle order for all songs, and set shuffle position to current song if provided
  void _generateShuffleOrder({int? currentIndex}) {
    final length = _songs.length;
    if (length <= 1) {
      _shuffleOrder = List.generate(length, (i) => i);
      _shufflePosition = 0;
      return;
    }
    final indices = List<int>.generate(length, (i) => i);
    indices.shuffle();
    _shuffleOrder = indices;
    if (currentIndex != null && _shuffleOrder.contains(currentIndex)) {
      _shufflePosition = _shuffleOrder.indexOf(currentIndex);
    } else {
      _shufflePosition = 0;
    }
  }

  // Next in shuffle order
  Future<void> playNext() async {
    if (playMode == 3 && _songs.length > 1) {
      if (_shuffleOrder.isEmpty || _shuffleOrder.length != _songs.length) {
        _generateShuffleOrder(currentIndex: player.currentIndex ?? 0);
      }
      if (_shufflePosition < _shuffleOrder.length - 1) {
        _shufflePosition++;
      } else {
        // End of shuffle order, reshuffle for a new session and continue (non-stop)
        _generateShuffleOrder(currentIndex: null);
        _shufflePosition = 0;
      }
      final nextIndex = _shuffleOrder[_shufflePosition];
      await player.seek(Duration.zero, index: nextIndex);
      currentIndexNotifier.value = nextIndex;
      await player.play();
    } else {
      await player.seekToNext();
      await player.play();
    }
  }

  // Previous in shuffle order
  Future<void> playPrevious() async {
    if (playMode == 3 && _songs.length > 1) {
      if (_shuffleOrder.isEmpty || _shuffleOrder.length != _songs.length) {
        _generateShuffleOrder(currentIndex: player.currentIndex ?? 0);
      }
      if (_shufflePosition > 0) {
        _shufflePosition--;
        final prevIndex = _shuffleOrder[_shufflePosition];
        await player.seek(Duration.zero, index: prevIndex);
        currentIndexNotifier.value = prevIndex;
        await player.play();
      }
      // If at the start, do nothing or restart current song
    } else {
      await player.seekToPrevious();
      await player.play();
    }
  }

  // --- Shuffle auto-next logic using player completion ---
  void _setupShuffleAutoNext() {
    _cancelShuffleAutoNext();
    _shuffleAutoNextSub = player.playerStateStream.listen((state) async {
      if (playMode == 3 &&
          state.processingState == ProcessingState.completed &&
          _songs.length > 1) {
        // Instead of letting just_audio advance, always use our shuffle logic
        await playNext();
      }
    });
  }

  void _cancelShuffleAutoNext() {
    _shuffleAutoNextSub?.cancel();
    _shuffleAutoNextSub = null;
  }
}
