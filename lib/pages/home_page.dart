import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseService _supabase = SupabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _songs = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _currentError;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadSongs();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.buffering) {
        setState(() => _isBuffering = true);
      } else if (event.processingState == ProcessingState.ready) {
        setState(() => _isBuffering = false);
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('Audio player error: $e');
      if (mounted) {
        setState(() {
          _currentError = 'Playback error: ${e.toString()}';
          _isPlaying = false;
        });
        _showSnackBar(
          message: 'Error playing audio',
          color: Colors.red,
        );
      }
    });
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _supabase.getSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
          _currentError = null;
        });
      }
      // Removed automatic playback after loading
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          message: 'Error loading songs: ${e.toString()}',
          color: Colors.red,
        );
        setState(() {
          _isLoading = false;
          _currentError = e.toString();
        });
      }
    }
  }

  Future<void> _playSong(int index) async {
    if (index < 0 || index >= _songs.length) return;

    try {
      setState(() {
        _currentIndex = index;
        _isPlaying = false;
        _currentError = null;
        _isBuffering = true;
      });

      final song = _songs[index];
      final audioPath = song['audio_path'] as String;
      final audioUrl = _supabase.getAudioUrl(audioPath);

      await _audioPlayer.stop();
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.load();
      await _audioPlayer.play();

      setState(() {
        _isPlaying = true;
        _isBuffering = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error in _playSong: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showSnackBar(
          message: 'Error playing song: ${e.toString()}',
          color: Colors.red,
        );
        setState(() {
          _currentError = 'Failed to play: ${e.toString()}';
          _isPlaying = false;
          _isBuffering = false;
        });
      }
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < _songs.length - 1) {
      await _playSong(_currentIndex + 1);
    } else {
      await _playSong(0);
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      await _playSong(_currentIndex - 1);
    } else {
      await _playSong(_songs.length - 1);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_songs.isNotEmpty) {
        await _playSong(_currentIndex);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _audioPlayer.dispose();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        message: 'Error signing out: ${e.toString()}',
        color: Colors.red,
      );
    }
  }

  void _showSnackBar({required String message, required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentSong = _songs.isNotEmpty ? _songs[_currentIndex] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Good Evening', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
          ? const Center(child: Text('No songs available', style: TextStyle(color: Colors.white70)))
          : Column(
        children: [
          // Current Song Display
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (currentSong?['image_path'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: CachedNetworkImage(
                        imageUrl: _supabase.getImageUrl(currentSong!['image_path']),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[800], child: const Icon(Icons.music_note, size: 60, color: Colors.white70)),
                        errorWidget: (context, url, error) => Container(color: Colors.grey[800], child: const Icon(Icons.error, color: Colors.white70)),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(currentSong?['title'] ?? 'Unknown Title', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                Text(currentSong?['artist'] ?? 'Unknown Artist', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapshot1) {
                    final position = snapshot1.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: _audioPlayer.durationStream,
                      builder: (context, snapshot2) {
                        final duration = snapshot2.data ?? Duration.zero;
                        return ProgressBar(
                          progress: position,
                          total: duration,
                          onSeek: (duration) => _audioPlayer.seek(duration),
                          progressBarColor: const Color(0xFF1DB954),
                          baseBarColor: Colors.white24,
                          bufferedBarColor: Colors.white38,
                          thumbColor: const Color(0xFF1DB954),
                          timeLabelTextStyle: const TextStyle(color: Colors.white70),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36), onPressed: _playPrevious),
                    IconButton(
                      icon: _isBuffering
                          ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1DB954)),
                      )
                          : Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 64, color: const Color(0xFF1DB954)),
                      onPressed: _togglePlayPause,
                    ),
                    IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 36), onPressed: _playNext),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Song List
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: _supabase.getImageUrl(song['image_path']),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[800], child: const Icon(Icons.music_note, color: Colors.white70, size: 20)),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[800], child: const Icon(Icons.error, color: Colors.white70, size: 20)),
                    ),
                  ),
                  title: Text(song['title'] ?? 'Unknown Title', style: TextStyle(color: Colors.white)),
                  subtitle: Text(song['artist'] ?? 'Unknown Artist', style: TextStyle(color: Colors.white70)),
                  trailing: _currentIndex == index ? const Icon(Icons.equalizer, color: Color(0xFF1DB954)) : null,
                  onTap: () => _playSong(index),
                  selected: _currentIndex == index,
                  selectedColor: Colors.white,
                  tileColor: _currentIndex == index ? Colors.grey[900] : Colors.transparent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}