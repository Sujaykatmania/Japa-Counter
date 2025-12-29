import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:japa_counter/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // We will handle system UI mode in the app, but setting a default here for now.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: JapaCounterApp()));
}

class JapaCounterApp extends StatelessWidget {
  const JapaCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Japa Counter',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFD700), // Soft Gold
        brightness: Brightness.dark,
        // background: const Color(0xFF1E1E1E), // Deprecated, using surface
        surface: const Color(0xFF1E1E1E), // Deep Charcoal
      ),
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }
}
