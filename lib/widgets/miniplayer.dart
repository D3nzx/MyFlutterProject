import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_player_service.dart';
import '../services/supabase_service.dart';
import '../pages/song_detail_screen.dart';
import 'dart:async';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final audioService = AudioPlayerService();
  final supabase = SupabaseService();

  int? _currentIndex;
  StreamSubscription<int?>? _currentIndexSub;

  @override
  void initState() {
    super.initState();
    _currentIndexSub = audioService.player.currentIndexStream.listen((newIndex) {
      if (mounted && newIndex != null && newIndex >= 0 && newIndex < audioService.songs.length) {
        setState(() {
          _currentIndex = newIndex;
        });
      }
    });
    _currentIndex = audioService.currentIndexNotifier.value;
  }

  @override
  void dispose() {
    _currentIndexSub?.cancel();
    super.dispose();
  }

  Future<void> _playNext() async {
    await audioService.playNext();
  }

  Future<void> _playPrevious() async {
    await audioService.playPrevious();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    if (currentIndex == null ||
        currentIndex < 0 ||
        currentIndex >= audioService.songs.length) {
      return const SizedBox.shrink();
    }
    final song = audioService.songs[currentIndex];
    final imageUrl = supabase.getImageUrl(song['image_path']);
    final title = song['title'] ?? '';
    final artist = song['artist'] ?? '';

    return StreamBuilder<bool>(
      stream: audioService.player.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.13 * 255).round()),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.18 * 255).round()),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SongDetailScreen(
                      initialIndex: currentIndex,
                      songs: List<Map<String, dynamic>>.from(audioService.songs),
                    ),
                  ),
                );
              },
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white70, size: 24),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.error, color: Colors.white70, size: 24),
                    ),
                  ),
                ),
                title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(artist, style: const TextStyle(color: Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                      onPressed: _playPrevious,
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: Colors.blueAccent,
                        size: 32,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          audioService.player.pause();
                        } else {
                          audioService.player.play();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                      onPressed: _playNext,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
