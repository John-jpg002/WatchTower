import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Add timeout to prevent hanging
    await Supabase.initialize(
      url: 'https://afjmndbunsqpaphikjqg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFmam1uZGJ1bnNxcGFwaGlranFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDg0MjIsImV4cCI6MjA5MDg4NDQyMn0.yeVLn_Xm9p7zNm2zq4CsFESFyRbZxfXLEuopRVz_9Mk',
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        // Throw timeout exception to be caught by catch block
        throw TimeoutException('Supabase initialization timed out', const Duration(seconds: 10));
      },
    );
  } catch (e) {
    print('Supabase initialization failed: $e');
    print('Running in offline mode');
  }
  
  runApp(const WatchtowerApp());
}

final supabase = Supabase.instance.client;

class WatchtowerApp extends StatelessWidget {
  const WatchtowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watchtower App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00C8E0),
          secondary: Color(0xFF0A4F6E),
          surface: Color(0xFF111827),
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
