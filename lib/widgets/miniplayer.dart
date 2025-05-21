import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_player_service.dart';
import '../services/supabase_service.dart';
import '../pages/song_detail_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final audioService = AudioPlayerService();
  final supabase = SupabaseService();

  Future<void> _playNext() async {
    final currentIndex = audioService.currentIndexNotifier.value;
    if (currentIndex != null && currentIndex < audioService.songs.length - 1) {
      final nextIndex = currentIndex + 1;
      final nextSong = audioService.songs[nextIndex];
      final audioUrl = supabase.getAudioUrl(nextSong['audio_path']);
      await audioService.playSongAt(nextIndex, audioUrl);
    }
  }

  Future<void> _playPrevious() async {
    final currentIndex = audioService.currentIndexNotifier.value;
    if (currentIndex != null && currentIndex > 0) {
      final prevIndex = currentIndex - 1;
      final prevSong = audioService.songs[prevIndex];
      final audioUrl = supabase.getAudioUrl(prevSong['audio_path']);
      await audioService.playSongAt(prevIndex, audioUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: audioService.currentIndexNotifier,
      builder: (context, currentIndex, _) {
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
            return Material(
              color: Colors.grey[900],
              child: InkWell(
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
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, color: Colors.white70, size: 20),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, color: Colors.white70, size: 20),
                      ),
                    ),
                  ),
                  title: Text(title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(artist, style: const TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: _playPrevious,
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
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
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: _playNext,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
