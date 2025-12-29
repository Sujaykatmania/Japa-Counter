import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:japa_counter/models/mantra.dart';
import 'package:japa_counter/providers/counter_provider.dart';
import 'package:japa_counter/screens/settings_screen.dart';
import 'package:japa_counter/widgets/circular_progress.dart';
import 'package:japa_counter/widgets/ripple_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Global Key to persist the Ripple Widget state across rebuilds
  final GlobalKey<RippleBackgroundState> rippleKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final counterState = ref.watch(counterProvider);
    final notifier = ref.read(counterProvider.notifier);
    final activeMantra = counterState.activeMantra;

    // Loading State
    if (activeMantra == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
      );
    }

    final mantraColor = Color(activeMantra.color);

    // Progress calculation
    final double progress = activeMantra.goal == 0
        ? 0
        : (activeMantra.count % activeMantra.goal) / activeMantra.goal;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF121212),
      // -----------------------------------------------------------
      // ROOT LAYOUT: Stack (Restored to fix layout shifts)
      // -----------------------------------------------------------
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ------------------------------------------------
          // LAYER 1: Background Visuals & Focus Mode Detector
          // ------------------------------------------------
          RippleBackground(
            key: rippleKey,
            rippleColor: mantraColor,
            child: Container(color: Colors.transparent),
          ),
          
          // The Tap Detector covers the WHOLE screen
          // Only active in Focus Mode (Non-Tactile)
          if (!counterState.isTactileMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  notifier.increment();
                  rippleKey.currentState?.addRipple(details.globalPosition);
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          // ------------------------------------------------
          // LAYER 2: Central Counter (Centered on Screen)
          // ------------------------------------------------
          // Wrapped in IgnorePointer so Focus Mode taps pass through it
          IgnorePointer(
            ignoring: !counterState.isTactileMode, 
            child: Center(
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
                          progress: progress,
                          color: mantraColor,
                          glowColor: mantraColor.withOpacity(0.5),
                          trackColor: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),

                    // Tactile Button Area (Only if active)
                    if (counterState.isTactileMode)
                      GestureDetector(
                        onTapDown: (details) {
                          notifier.increment();
                          rippleKey.currentState?.addRipple(details.globalPosition);
                        },
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
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Counter Text & Mala Info
                    IgnorePointer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "MALA: ${activeMantra.malaCount}",
                            style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 10),
                          _PulseText(
                            count: activeMantra.count,
                            key: ValueKey(activeMantra.count),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // LAYER 3: Bottom Elements (Reset & Goal)
          // ------------------------------------------------
          // Pinned to bottom to avoid overlapping the center ring
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Goal: ${activeMantra.goal}",
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onLongPress: () =>
                      _showResetOptions(context, notifier, activeMantra.id),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Hold to Reset",
                            style: GoogleFonts.outfit(color: Colors.black)),
                        backgroundColor: mantraColor,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: mantraColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.black.withOpacity(0.2),
                    ),
                    child: Text(
                      "HOLD TO RESET",
                      style: GoogleFonts.outfit(
                        color: mantraColor,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------
          // LAYER 4: Header (Settings & Streak)
          // ------------------------------------------------
          // This sits ON TOP. The GestureDetector ensures tapping empty space
          // in the header does NOT trigger the counter below.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                 // Block taps here from falling through to the counter
              },
              behavior: HitTestBehavior.opaque, 
              child: SafeArea(
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StreakBadge(streak: counterState.currentStreak),
                      Expanded(
                        child: Center(
                          child: _MantraSelector(
                            activeMantra: activeMantra,
                            mantras: counterState.mantras,
                            onSelect: (id) => notifier.selectMantra(id),
                            onAdd: () => _showAddMantraDialog(context, notifier),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings,
                            color: Colors.white.withOpacity(0.5)),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMantraDialog(BuildContext context, CounterNotifier notifier) {
    final nameController = TextEditingController();
    final goalController = TextEditingController(text: "108");

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: Text("New Mantra",
                  style: GoogleFonts.outfit(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: "Mantra Name",
                        labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  TextField(
                    controller: goalController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: "Goal (e.g. 108)",
                        labelStyle: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                TextButton(
                  child: const Text("Create"),
                  onPressed: () {
                    final goal = int.tryParse(goalController.text) ?? 108;
                    if (nameController.text.isNotEmpty) {
                      notifier.addMantra(nameController.text, goal);
                      Navigator.pop(ctx);
                    }
                  },
                )
              ],
            ));
  }

  void _showResetOptions(
      BuildContext context, CounterNotifier notifier, String mantraId) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Reset Options",
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading:
                        const Icon(Icons.refresh, color: Colors.orangeAccent),
                    title: Text("Reset Current Count",
                        style: GoogleFonts.outfit(color: Colors.white)),
                    subtitle: Text("Sets count to 0, keeps Mala count",
                        style: GoogleFonts.outfit(color: Colors.white54)),
                    onTap: () {
                      notifier.resetCurrentCount(mantraId);
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: Colors.redAccent),
                    title: Text("Reset Full History",
                        style: GoogleFonts.outfit(color: Colors.white)),
                    subtitle: Text("Sets Count AND Mala count to 0",
                        style: GoogleFonts.outfit(color: Colors.white54)),
                    onTap: () {
                      notifier.resetFullHistory(mantraId);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ));
  }
}

// ----------------------------------------------------------
// HELPER CLASSES (Badge, Selector, Pulse Text)
// ----------------------------------------------------------

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 4),
          Text("$streak",
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MantraSelector extends StatelessWidget {
  final Mantra activeMantra;
  final List<Mantra> mantras;
  final Function(String) onSelect;
  final VoidCallback onAdd;

  const _MantraSelector(
      {required this.activeMantra,
      required this.mantras,
      required this.onSelect,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: Color(activeMantra.color), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                activeMantra.name.toUpperCase(),
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  void _showSelector(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              builder: (_, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Select Mantra",
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFFFFD700)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onAdd();
                          }),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  ...mantras.map((m) => ListTile(
                        leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: Color(m.color), shape: BoxShape.circle)),
                        title: Text(m.name,
                            style: GoogleFonts.outfit(color: Colors.white)),
                        subtitle: Text(
                            "Malas: ${m.malaCount}  •  Goal: ${m.goal}",
                            style: GoogleFonts.outfit(color: Colors.white54)),
                        trailing: m.id == activeMantra.id
                            ? const Icon(Icons.check, color: Color(0xFFFFD700))
                            : null,
                        onTap: () {
                          onSelect(m.id);
                          Navigator.pop(ctx);
                        },
                      )),
                ],
              ),
            ));
  }
}

class _PulseText extends StatefulWidget {
  final int count;
  final Color color;
  const _PulseText({super.key, required this.count, this.color = Colors.white});

  @override
  State<_PulseText> createState() => _PulseTextState();
}

class _PulseTextState extends State<_PulseText>
    with SingleTickerProviderStateMixin {
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
            color: widget.color,
            shadows: [
              Shadow(
                blurRadius: 20,
                color: widget.color.withOpacity(0.4),
                offset: const Offset(0, 0),
              ),
            ]),
      ),
    );
  }
}