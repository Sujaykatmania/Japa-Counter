import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
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
            child: activeMantra.backgroundPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(activeMantra.backgroundPath!),
                        fit: BoxFit.cover,
                      ),
                      Container(
                        color: Colors.black
                            .withValues(alpha: activeMantra.overlayOpacity),
                      ),
                    ],
                  )
                : Container(color: Colors.transparent),
          ),

          // The Tap Detector covers the screen but leaves bottom safe
          // Only active in Focus Mode (Non-Tactile)
          if (!counterState.isTactileMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 50, // Safe Zone for Navigation Home Bar
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
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
                              glowColor: mantraColor.withValues(alpha: 0.5),
                              trackColor: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),

                        // Tactile Button Area (Only if active)
                        if (counterState.isTactileMode)
                          GestureDetector(
                            onTapDown: (details) {
                              notifier.increment();
                              rippleKey.currentState
                                  ?.addRipple(details.globalPosition);
                            },
                            child: ClipOval(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
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
                                    color: Colors.white.withValues(alpha: 0.5),
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
                  if (activeMantra.chantText != null &&
                      activeMantra.chantText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              activeMantra.chantText!,
                              style: GoogleFonts.cinzel(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------
          // LAYER 3: Bottom Elements (Reset & Goal & Undo)
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
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Undo Button
                    GestureDetector(
                      onTap: () => notifier.decrement(),
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color.fromARGB(151, 255, 255, 255)),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                    ),

                    // Reset Button
                    GestureDetector(
                      onLongPress: () async {
                        HapticFeedback.heavyImpact();
                        await Future.delayed(const Duration(milliseconds: 150));
                        HapticFeedback.heavyImpact();
                        if (context.mounted) {
                          _showResetOptions(context, notifier, activeMantra.id);
                        }
                      },
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Keep Holding to Reset...",
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16), // Increased hit area
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: mantraColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.black.withValues(alpha: 0.2),
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
                            notifier: notifier,
                            onSelect: (id) => notifier.selectMantra(id),
                            onAdd: () =>
                                _showAddMantraDialog(context, notifier),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings,
                            color: Colors.white.withValues(alpha: 0.5)),
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

          // ------------------------------------------------
          // LAYER 5: Mala Completion Overlay
          // ------------------------------------------------
          if (counterState.isMalaCompleted)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFFFFD700), size: 80),
                      const SizedBox(height: 30),
                      Text("Mala Completed!",
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text("${activeMantra.goal} chants done",
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 50),
                      GestureDetector(
                        onTap: () {
                          notifier.completeMala();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 20),
                          decoration: BoxDecoration(
                              color: mantraColor,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                    color: mantraColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10))
                              ]),
                          child: Text("START NEXT MALA",
                              style: GoogleFonts.outfit(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1)),
                        ),
                      )
                    ],
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
        color: Colors.white.withValues(alpha: 0.1),
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
  final CounterNotifier notifier;
  final Function(String) onSelect;
  final VoidCallback onAdd;

  const _MantraSelector(
      {required this.activeMantra,
      required this.mantras,
      required this.notifier,
      required this.onSelect,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
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
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 0),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.id == activeMantra.id)
                              const Icon(Icons.check, color: Color(0xFFFFD700)),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white54),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.pop(ctx);
                                  _showEditDialog(context, m);
                                } else if (value == 'delete') {
                                  Navigator.pop(ctx);
                                  _showDeleteDialog(context, m);
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text("Edit",
                                        style: GoogleFonts.outfit(
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255))),
                                  ),
                                  if (mantras.length > 1)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text("Delete",
                                          style: GoogleFonts.outfit(
                                              color: Colors.red)),
                                    ),
                                ];
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          onSelect(m.id);
                          Navigator.pop(ctx);
                        },
                      )),
                ],
              ),
            ));
  }

  void _showEditDialog(BuildContext context, Mantra mantra) {
    showDialog(
      context: context,
      builder: (ctx) => _EditMantraDialog(mantra: mantra, notifier: notifier),
    );
  }

  void _showDeleteDialog(BuildContext context, Mantra mantra) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: Text("Delete Mantra?",
                  style: GoogleFonts.outfit(color: Colors.white)),
              content: Text(
                  "Are you sure you want to delete '${mantra.name}'? This action cannot be undone.",
                  style: GoogleFonts.outfit(color: Colors.white70)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                TextButton(
                  child:
                      const Text("Delete", style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    notifier.deleteMantra(mantra.id);
                    Navigator.pop(ctx);
                  },
                )
              ],
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
                color: widget.color.withValues(alpha: 0.4),
                offset: const Offset(0, 0),
              ),
            ]),
      ),
    );
  }
}

class _EditMantraDialog extends StatefulWidget {
  final Mantra mantra;
  final CounterNotifier notifier;

  const _EditMantraDialog({required this.mantra, required this.notifier});

  @override
  State<_EditMantraDialog> createState() => _EditMantraDialogState();
}

class _EditMantraDialogState extends State<_EditMantraDialog> {
  late TextEditingController nameController;
  late TextEditingController goalController;
  late TextEditingController chantController;
  String? bgPath;
  double overlayOpacity = 0.5;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.mantra.name);
    goalController = TextEditingController(text: widget.mantra.goal.toString());
    chantController = TextEditingController(text: widget.mantra.chantText);
    bgPath = widget.mantra.backgroundPath;
    overlayOpacity = widget.mantra.overlayOpacity;
  }

  @override
  void dispose() {
    nameController.dispose();
    goalController.dispose();
    chantController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Persistence Logic: Copy to App Doc Dir
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(image.path);
      final savedImage =
          await File(image.path).copy('${appDir.path}/$fileName');

      setState(() {
        bgPath = savedImage.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mantra Color for slider active color
    final mColor = Color(widget.mantra.color);

    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title:
          Text("Edit Mantra", style: GoogleFonts.outfit(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: nameController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Mantra Name",
                  labelStyle: TextStyle(color: Colors.white54)),
            ),

            // Goal
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Goal",
                  labelStyle: TextStyle(color: Colors.white54)),
            ),

            // Chant Text
            TextField(
              controller: chantController,
              maxLines: 2,
              style: GoogleFonts.cinzel(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Chant Text / Prayer",
                  labelStyle: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 25),

            // Visuals Section Header
            Text("Background Visuals",
                style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // LIVE PREVIEW Container
            // Shows the effect of the image + opacity
            Center(
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bgPath != null)
                      Image.file(File(bgPath!), fit: BoxFit.cover),

                    // Overlay Preview
                    Container(
                      color: bgPath != null
                          ? Colors.black.withValues(alpha: overlayOpacity)
                          : Colors
                              .transparent, // Only show overlay if image exists
                    ),

                    // Label if empty
                    if (bgPath == null)
                      Center(
                          child: Text("No Image Selected",
                              style:
                                  GoogleFonts.outfit(color: Colors.white24))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: Text(bgPath == null ? "Pick" : "Change"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
                if (bgPath != null)
                  TextButton.icon(
                      onPressed: () => setState(() => bgPath = null),
                      icon: const Icon(Icons.close,
                          color: Colors.redAccent, size: 18),
                      label: Text("Remove",
                          style: GoogleFonts.outfit(color: Colors.redAccent)))
              ],
            ),

            // Opacity Slider (Only if image selected)
            if (bgPath != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Dimming",
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 12)),
                  Text("${(overlayOpacity * 100).toInt()}%",
                      style: GoogleFonts.outfit(
                          color: mColor, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: overlayOpacity,
                min: 0.0,
                max: 1.0,
                activeColor: mColor,
                inactiveColor: Colors.white10,
                onChanged: (val) {
                  setState(() {
                    overlayOpacity = val;
                  });
                },
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        TextButton(
          child: const Text("Save"),
          onPressed: () {
            final goal = int.tryParse(goalController.text) ?? 108;
            if (nameController.text.isNotEmpty) {
              widget.notifier.updateMantra(
                widget.mantra.id,
                name: nameController.text,
                goal: goal,
                backgroundPath: bgPath,
                overlayOpacity: overlayOpacity,
                chantText:
                    chantController.text.isEmpty ? null : chantController.text,
              );
              Navigator.pop(context);
            }
          },
        )
      ],
    );
  }
}
