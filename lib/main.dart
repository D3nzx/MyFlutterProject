import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugLog('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugLog('Firebase initialized successfully');
    runApp(const MyApp());
  } catch (e) {
    debugLog('Failed to initialize Firebase: $e', isError: true);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error: ${e.toString()}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please check your Firebase configuration and internet connection',
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
      title: 'Final Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
      onUnknownRoute: (settings) {
        debugLog('Attempted to navigate to unknown route: ${settings.name}', isError: true);
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
    );
  }
}