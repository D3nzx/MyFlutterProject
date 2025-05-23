import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _supabaseUrl = 'https://juqjgxwqgzbywomhimbq.supabase.co';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1cWpneHdxZ3pieXdvbWhpbWJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0OTQyOTgsImV4cCI6MjA2MzA3MDI5OH0.sLooiRem0Ld0IKw_QYL5B2R1WcVUDVEqSPWtXt5iTFw';

  late final SupabaseClient client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseKey,
    );
    client = Supabase.instance.client;
  }

  Future<List<Map<String, dynamic>>> getSongs({bool ascending = true}) async {
    try {
      final response = await client
          .from('songs')
          .select('*')
          .order('title', ascending: ascending);

      // Filter out any null or invalid entries
      return (List<Map<String, dynamic>>.from(response)).where((song) {
        return song['title'] != null &&
            song['artist'] != null &&
            song['audio_path'] != null &&
            song['image_path'] != null;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching songs: $e');
      return [];
    }
  }

  String getPublicUrl(String path) {
    final cleanPath = path.split('?').first;
    final encodedPath = Uri.encodeComponent(cleanPath);
    return '$_supabaseUrl/storage/v1/object/public/songs/$encodedPath';
  }

  String getAudioUrl(String audioPath) {
    return getPublicUrl(audioPath);
  }

  String getImageUrl(String imagePath) {
    return getPublicUrl(imagePath);
  }
}
