import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../services/supabase_service.dart';
import '../services/audio_player_service.dart';

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
  }

  Future<void> _initAudioPlayer() async {
    try {
      final currentSong = widget.songs[_currentIndex];
      final audioUrl = _supabase.getAudioUrl(currentSong['audio_path']);

      // Set up player state listeners
      _audioPlayer.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;

        setState(() {
          _isPlaying = isPlaying;
          _isBuffering = processingState == ProcessingState.buffering;
          _isLoading = processingState == ProcessingState.loading;
        });
      });

      _audioPlayer.durationStream.listen((duration) {
        setState(() => _duration = duration);
      });

      _audioPlayer.positionStream.listen((position) {
        setState(() => _position = position);
      });

      // Only play if not already playing the correct song
      final audioService = AudioPlayerService();
      audioService.setSongs(widget.songs);
      if (audioService.currentIndexNotifier.value != _currentIndex ||
          audioService.player.audioSource == null) {
        await audioService.playSongAt(_currentIndex, audioUrl);
      }
      // else: do nothing, keep playing current song
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing song: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _playNextSong() async {
    if (_currentIndex < widget.songs.length - 1) {
      setState(() {
        _currentIndex++;
        _isLoading = true;
      });
      await _loadAndPlayCurrentSong();
    }
  }

  Future<void> _playPreviousSong() async {
    if (_position != null && _position!.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isLoading = true;
      });
      await _loadAndPlayCurrentSong();
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> _loadAndPlayCurrentSong() async {
    try {
      final currentSong = widget.songs[_currentIndex];
      final audioUrl = _supabase.getAudioUrl(currentSong['audio_path']);

      await AudioPlayerService().playSongAt(_currentIndex, audioUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing song: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Do not dispose the global player here!
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Album Art
              Expanded(
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
              ),
              const SizedBox(height: 32),

              // Song Info
              Expanded(
                flex: 1,
                child: Column(
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
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ProgressBar(
                  progress: _position ?? Duration.zero,
                  total: _duration ?? Duration.zero,
                  onSeek: (duration) => _audioPlayer.seek(duration),
                  progressBarColor: Colors.white,
                  baseBarColor: Colors.grey[600]!,
                  bufferedBarColor: Colors.grey[800]!,
                  thumbColor: Colors.white,
                  timeLabelTextStyle: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),

              // Controls
              Expanded(
                flex: 1,
                child: Row(
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
                              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
