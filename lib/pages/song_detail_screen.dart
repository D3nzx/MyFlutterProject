import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../services/supabase_service.dart';
import '../services/audio_player_service.dart';
import 'dart:async';

class SongDetailScreen extends StatefulWidget {
  final int initialIndex;
  final List<Map<String, dynamic>> songs;

  const SongDetailScreen({
    super.key,
    required this.initialIndex,
    required this.songs,
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late final SupabaseService _supabase;
  late final AudioPlayer _audioPlayer;
  late final StreamSubscription<int?> _currentIndexSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  late int _currentIndex;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isBuffering = false;
  Duration? _duration;
  Duration? _position;

  @override
  void initState() {
    super.initState();
    _supabase = SupabaseService();
    _audioPlayer = AudioPlayerService().player;
    _currentIndex = widget.initialIndex;
    _initAudioPlayer();

    _currentIndexSub = _audioPlayer.currentIndexStream.listen((newIndex) {
      if (newIndex != null && newIndex >= 0 && newIndex < widget.songs.length) {
        setState(() {
          _currentIndex = newIndex;
        });
      }
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      setState(() {
        _isPlaying = isPlaying;
        _isBuffering = processingState == ProcessingState.buffering;
        _isLoading = processingState == ProcessingState.loading;
      });
    });

    _durationSub = _audioPlayer.durationStream.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSub = _audioPlayer.positionStream.listen((position) {
      setState(() => _position = position);
    });
  }

  Future<void> _initAudioPlayer() async {
    try {
      final currentSong = widget.songs[_currentIndex];
      final audioUrl = _supabase.getAudioUrl(currentSong['audio_path']);

      final audioService = AudioPlayerService();
      audioService.setSongs(widget.songs);
      if (audioService.currentIndexNotifier.value != _currentIndex ||
          audioService.player.audioSource == null) {
        await audioService.playSongAt(_currentIndex, audioUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing song: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _playNextSong() async {
    await AudioPlayerService().playNext();
  }

  Future<void> _playPreviousSong() async {
    await AudioPlayerService().playPrevious();
  }

  @override
  void dispose() {
    _currentIndexSub.cancel();
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.songs[_currentIndex];
    final imageUrl = _supabase.getImageUrl(currentSong['image_path']);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            final albumArt = Expanded(
              flex: 3,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.music_note, color: Colors.white70, size: 50),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.white70, size: 50),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

            final songInfoAndControls = Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: isLandscape ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    // Song title and artist
                    Column(
                      children: [
                        Text(
                          currentSong['title'] ?? 'Unknown Title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentSong['artist'] ?? 'Unknown Artist',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ProgressBar(
                        progress: _position ?? Duration.zero,
                        total: _duration ?? Duration.zero,
                        onSeek: (duration) async {
                          final audioService = AudioPlayerService();
                          final isShuffle = audioService.playModeNotifier.value == 3;
                          final total = _duration ?? Duration.zero;
                          if (isShuffle && total.inMilliseconds > 0 && duration.inMilliseconds >= total.inMilliseconds - 500) {
                            await audioService.playNext();
                          } else {
                            _audioPlayer.seek(duration);
                          }
                        },
                        progressBarColor: Colors.white,
                        baseBarColor: Colors.grey[600]!,
                        bufferedBarColor: Colors.grey[800]!,
                        thumbColor: Colors.white,
                        timeLabelTextStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Play mode button
                    ValueListenableBuilder<int>(
                      valueListenable: AudioPlayerService().playModeNotifier,
                      builder: (context, playMode, _) {
                        IconData icon;
                        Color color = Colors.white;
                        String tooltip;
                        switch (playMode) {
                          case 1:
                            icon = Icons.repeat_one;
                            color = Colors.blueAccent;
                            tooltip = 'Repeat One: Repeat current song endlessly';
                            break;
                          case 2:
                            icon = Icons.repeat;
                            color = Colors.blueAccent;
                            tooltip = 'Repeat All: Repeat playlist from start after last song';
                            break;
                          case 3:
                            icon = Icons.shuffle;
                            color = Colors.blueAccent;
                            tooltip = 'Shuffle All: Play all songs in random order, repeat all';
                            break;
                          default:
                            icon = Icons.repeat;
                            color = Colors.white;
                            tooltip = 'Off: Play songs in order, stop after last song';
                        }
                        return IconButton(
                          icon: Icon(icon, color: color),
                          tooltip: tooltip,
                          onPressed: () {
                            int nextMode = (playMode + 1) % 4;
                            AudioPlayerService().setPlayMode(nextMode);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Playback controls
                    Expanded(
                      child: StreamBuilder<PlayerState>(
                        stream: _audioPlayer.playerStateStream,
                        builder: (context, snapshot) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous, size: 40),
                                color: Colors.white,
                                onPressed: _isLoading ? null : _playPreviousSong,
                              ),
                              IconButton(
                                icon: _isLoading || _isBuffering
                                    ? const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        size: 60,
                                      ),
                                color: Colors.white,
                                onPressed: (_isLoading || _isBuffering)
                                    ? null
                                    : () async {
                                        if (_isPlaying) {
                                          await _audioPlayer.pause();
                                        } else {
                                          await _audioPlayer.play();
                                        }
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next, size: 40),
                                color: Colors.white,
                                onPressed: _isLoading ? null : _playNextSong,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (isLandscape) {
              return Row(
                children: [
                  Flexible(flex: 4, child: albumArt),
                  Flexible(flex: 6, child: songInfoAndControls),
                ],
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    albumArt,
                    const SizedBox(height: 32),
                    songInfoAndControls,
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
