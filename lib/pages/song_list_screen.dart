import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/supabase_service.dart';
import 'song_detail_screen.dart';
import '../services/audio_player_service.dart';
import '../widgets/miniplayer.dart';

class SongListScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? songs;

  const SongListScreen({super.key, this.songs});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _filteredSongs = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.songs != null) {
      _songs = widget.songs!;
      _filteredSongs = _songs;
      _isLoading = false;
      AudioPlayerService().setSongs(_songs);
    } else {
      _loadSongs();
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _supabase.getSongs();
      setState(() {
        _songs = songs;
        _filteredSongs = songs;
        _isLoading = false;
      });
      AudioPlayerService().setSongs(songs);
    } catch (e) {
      setState(() {
        _error = 'Failed to load songs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _songs;
      } else {
        _filteredSongs = _songs.where((song) {
          final title = (song['title'] ?? '').toLowerCase();
          final artist = (song['artist'] ?? '').toLowerCase();
          return title.contains(query) || artist.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Song List', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: const [
                      Icon(Icons.logout, color: Color(0xFF1DA1F2)),
                      SizedBox(width: 8),
                      Text(
                        'Confirm Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to log out?\nYour music will stop playing.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'No, Stay',
                        style: TextStyle(color: Color(0xFF1DA1F2)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DA1F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Yes, Log Out',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                await AudioPlayerService().stop(); // Stop all music
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by title or artist...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _songs.isEmpty
                ? const Center(child: Text('No songs available.', style: TextStyle(color: Colors.white70)))
                : _filteredSongs.isEmpty && _searchController.text.isNotEmpty
                ? const Center(child: Text('No results found.', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
              itemCount: _filteredSongs.isEmpty && _searchController.text.isEmpty
                  ? _songs.length
                  : _filteredSongs.length,
              itemBuilder: (context, index) {
                final song = _filteredSongs.isEmpty && _searchController.text.isEmpty
                    ? _songs[index]
                    : _filteredSongs[index];
                final originalIndex = _songs.indexOf(song);
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
                    final audioPlayerService = AudioPlayerService();
                    audioPlayerService.setSongs(_songs);
                    final audioUrl = _supabase.getAudioUrl(song['audio_path']);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SongDetailScreen(
                          initialIndex: originalIndex,
                          songs: _songs,
                        ),
                      ),
                    );
                    audioPlayerService.playSongAt(originalIndex, audioUrl);
                  },
                );
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
