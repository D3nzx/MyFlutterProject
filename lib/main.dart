import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/song_detail_screen.dart';
import 'pages/song_list_screen.dart';
import 'services/supabase_service.dart';
import 'pages/register_page.dart';

void debugLog(String message, {bool isError = false}) {
  assert(() {
    if (isError) {
      debugPrint('❌ ERROR: $message');
    } else {
      debugPrint('ℹ️ INFO: $message');
    }
    return true;
  }());
}

Future<void> initializeApp() async {
  // Initialize Firebase
  debugLog('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugLog('Firebase initialized successfully');

  // Initialize Supabase through the service
  debugLog('Initializing Supabase...');
  await SupabaseService().initialize();
  debugLog('Supabase initialized successfully');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeApp();
    runApp(const MyApp());
  } catch (e) {
    debugLog('Initialization failed: $e', isError: true);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error: ${e.toString()}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please check your configuration and internet connection',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/songList': (context) => const SongListScreen(),
        '/songDetail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          final int initialIndex = args['initialIndex'] ?? 0;
          final List<Map<String, dynamic>> songs = (args['songs'] as List<Map<String, dynamic>>?) ?? [];

          return SongDetailScreen(
            initialIndex: initialIndex,
            songs: songs,
          );
        },
      },
      onUnknownRoute: (settings) {
        debugLog(
            'Attempted to navigate to unknown route: ${settings.name}',
            isError: true);
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
    );
  }
}
