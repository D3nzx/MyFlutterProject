import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import 'song_detail_screen.dart';

class SongListScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? songs;

  const SongListScreen({super.key, this.songs});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.songs != null) {
      _songs = widget.songs!;
      _isLoading = false;
    } else {
      _loadSongs();
    }
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _supabase.getSongs();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load songs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Song List', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _songs.isEmpty
          ? const Center(child: Text('No songs available.', style: TextStyle(color: Colors.white70)))
          : ListView.builder(
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
            title: Text(
              song['title'] ?? 'Unknown Title',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              song['artist'] ?? 'Unknown Artist',
              style: const TextStyle(color: Colors.white70),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongDetailScreen(
                    initialIndex: index,
                    songs: _songs,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
