import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:japa_counter/providers/counter_provider.dart';
import 'package:japa_counter/screens/settings_screen.dart'; // We will create this next
import 'package:japa_counter/widgets/circular_progress.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterState = ref.watch(counterProvider);
    final isZen = counterState.isZenMode;

    return Scaffold(
      // Allow content to go behind status/nav bars if Zen
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient (Subtle)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1E1E),
                  Color(0xFF121212),
                ],
              ),
            ),
          ),
          
          // Main Interactive Area
          if (!counterState.isTactileMode) 
            // Focus Mode: Full screen tap
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref.read(counterProvider.notifier).increment(),
                child: Container(color: Colors.transparent),
              ),
            ),

          // Central Counting UI
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Progress Ring
                   RepaintBoundary(
                     child: CustomPaint(
                       size: const Size(300, 300),
                       painter: CircularProgressPainter(
                         progress: counterState.progress,
                         color: const Color(0xFFFFD700), // Gold
                         glowColor: const Color(0xFFFFD700).withOpacity(0.6),
                       ),
                     ),
                   ),

                   // Glassmorphism Center Circle (Tactile Button Area)
                   if (counterState.isTactileMode)
                     GestureDetector(
                       onTap: () => ref.read(counterProvider.notifier).increment(),
                       child: ClipOval(
                         child: BackdropFilter(
                           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                           child: Container(
                             width: 240,
                             height: 240,
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.05),
                               shape: BoxShape.circle,
                               border: Border.all(
                                 color: Colors.white.withOpacity(0.1),
                                 width: 1,
                               ),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.black.withOpacity(0.2),
                                   blurRadius: 20,
                                   spreadRadius: 5,
                                 )
                               ]
                             ),
                             alignment: Alignment.center,
                           ),
                         ),
                       ),
                     ),

                    // Counter Text (with Pulse trigger key)
                    // We can use a simple scaling animation on change
                    _PulseText(
                      count: counterState.count,
                      key: ValueKey(counterState.count),
                    ),
                ],
              ),
            ),
          ),

          // Settings Button (Top Right)
          // Hide in Zen Mode? Maybe make it very subtle or require specific gesture.
          // User said "Zen Mode toggles System UI". Maybe we keep the Settings button but make it low contrast.
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.white.withOpacity(0.3)),
              onPressed: () {
                 Navigator.push(
                   context, 
                   MaterialPageRoute(builder: (_) => const SettingsScreen())
                 );
              },
            ),
          ),
          
          // Reset Button (Tactile Mode Only - Small secondary button)
          if (counterState.isTactileMode)
            Positioned(
              bottom: 100,
              child: TextButton(
                onPressed: () => ref.read(counterProvider.notifier).reset(),
                child: Text(
                  "RESET", 
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 2,
                  )
                ),
              ),
            ),
            
          // Goal Indicator (Bottom center)
          Positioned(
            bottom: 60,
            child: Text(
              "Goal: ${counterState.goal}",
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseText extends StatefulWidget {
  final int count;
  const _PulseText({super.key, required this.count});

  @override
  State<_PulseText> createState() => _PulseTextState();
}

class _PulseTextState extends State<_PulseText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Text(
        "${widget.count}",
        style: GoogleFonts.outfit(
          fontSize: 64,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
             Shadow(
               blurRadius: 20,
               color: const Color(0xFFFFD700).withOpacity(0.4),
               offset: const Offset(0, 0),
             ),
          ]
        ),
      ),
    );
  }
}
