import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:japa_counter/providers/counter_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterState = ref.watch(counterProvider);
    final notifier = ref.read(counterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: "Preferences"),
          _SettingsTile(
            title: "Tactile Mode",
            subtitle: "Button interface vs Full screen tap",
            value: counterState.isTactileMode,
            onChanged: (val) => notifier.toggleMode(),
          ),
          _SettingsTile(
            title: "Zen Mode",
            subtitle: "Hide system status bars",
            value: counterState.isZenMode,
            onChanged: (val) => notifier.toggleZenMode(),
          ),
          
          const SizedBox(height: 30),
          _SectionHeader(title: "Goal"),
          ListTile(
            title: Text("Target Count", style: GoogleFonts.outfit(color: Colors.white)),
            trailing: Text(
              "${counterState.goal}",
              style: GoogleFonts.outfit(color: const Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold),
            ),
            onTap: () => _showGoalDialog(context, notifier, counterState.goal),
          ),
          
          const SizedBox(height: 30),
          _SectionHeader(title: "History"),
          if (counterState.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "No history yet.",
                style: GoogleFonts.outfit(color: Colors.white54),
              ),
            ),
          ...counterState.history.reversed.map((entry) { // Show newest first
             return ListTile(
               title: Text(
                 entry['date'] as String,
                 style: GoogleFonts.outfit(color: Colors.white70),
               ),
               trailing: Text(
                 "${entry['count']}",
                 style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
               ),
             );
          }).toList(),
          
          const SizedBox(height: 50),
          Center(
             child: TextButton(
               onPressed: () {
                 // Danger zone? Just reset count? 
                 // HomeScreen has a reset button. 
                 // Maybe "Clear History"? Not required yet.
               },
               child: Text("Japa Counter v1.0", style: GoogleFonts.outfit(color: Colors.white24)),
             ),
          )
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, CounterNotifier notifier, int currentGoal) {
    final controller = TextEditingController(text: "$currentGoal");
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text("Set Goal", style: GoogleFonts.outfit(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Save"),
            onPressed: () {
               final val = int.tryParse(controller.text);
               if (val != null && val > 0) {
                 notifier.setGoal(val);
               }
               Navigator.pop(ctx);
            },
          ),
        ],
      )
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          color: const Color(0xFFFFD700),
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.outfit(color: Colors.white)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
      value: value, 
      onChanged: onChanged,
      activeColor: const Color(0xFFFFD700),
      contentPadding: EdgeInsets.zero,
    );
  }
}
