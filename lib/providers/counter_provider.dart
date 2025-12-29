import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// State Class
class CounterState {
  final int count;
  final int goal;
  final bool isZenMode;
  final bool isTactileMode;
  final List<Map<String, dynamic>> history; // [{'date': '2023-10-27', 'count': 108}]

  const CounterState({
    this.count = 0,
    this.goal = 108,
    this.isZenMode = false,
    this.isTactileMode = true,
    this.history = const [],
  });

  CounterState copyWith({
    int? count,
    int? goal,
    bool? isZenMode,
    bool? isTactileMode,
    List<Map<String, dynamic>>? history,
  }) {
    return CounterState(
      count: count ?? this.count,
      goal: goal ?? this.goal,
      isZenMode: isZenMode ?? this.isZenMode,
      isTactileMode: isTactileMode ?? this.isTactileMode,
      history: history ?? this.history,
    );
  }

  // Double progress for UI
  double get progress => goal == 0 ? 0 : (count % goal) / goal;
  
  // Total cycles completed (optional usage)
  int get cycles => goal == 0 ? 0 : count ~/ goal;
}

// Notifier
class CounterNotifier extends StateNotifier<CounterState> {
  CounterNotifier() : super(const CounterState()) {
    _loadState();
  }

  static const _keyCount = 'count';
  static const _keyGoal = 'goal';
  static const _keyZen = 'zen_mode';
  static const _keyTactile = 'tactile_mode';
  static const _keyHistory = 'history';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyCount) ?? 0;
    final goal = prefs.getInt(_keyGoal) ?? 108;
    final isZen = prefs.getBool(_keyZen) ?? false;
    final isTactile = prefs.getBool(_keyTactile) ?? true;
    final historyString = prefs.getString(_keyHistory);
    
    List<Map<String, dynamic>> history = [];
    if (historyString != null) {
      try {
        history = List<Map<String, dynamic>>.from(json.decode(historyString));
      } catch (e) {
        // Handle corruption or format change gracefully
        history = [];
      }
    }

    state = CounterState(
      count: count,
      goal: goal,
      isZenMode: isZen,
      isTactileMode: isTactile,
      history: history,
    );
    
    // Enforce Zen Mode on load if active
    if (isZen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCount, state.count);
    await prefs.setInt(_keyGoal, state.goal);
    await prefs.setBool(_keyZen, state.isZenMode);
    await prefs.setBool(_keyTactile, state.isTactileMode);
    await prefs.setString(_keyHistory, json.encode(state.history));
  }

  void increment() {
    HapticFeedback.lightImpact(); // 'Bead' feel
    
    final newCount = state.count + 1;
    
    // Check for goal completion
    if (newCount > 0 && newCount % state.goal == 0) {
      HapticFeedback.heavyImpact(); // Distinct thump
      // Could play sound here if requested
    }

    state = state.copyWith(count: newCount);
    _saveState();
    _updateDailyHistory(newCount);
  }

  void _updateDailyHistory(int currentTotal) {
    // Determine 'today' key
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    List<Map<String, dynamic>> newHistory = List.from(state.history);
    
    // Check if today exists
    final index = newHistory.indexWhere((element) => element['date'] == today);
    if (index != -1) {
      newHistory[index] = {'date': today, 'count': currentTotal}; 
      // Note: This logic assumes 'count' is essentially lifetime or we'd need daily logic.
      // User said: "List<Map> to store daily totals".
      // If the user resets the main count, how does that affect history?
      // A typical Japa counter accumulates. Let's assume the global count is what we track.
      // Or maybe we track the *delta*? 
      // Simplified: Just recording the snapshot of the counter at the end of the day.
      // BUT, if I reset, history shouldn't disappear.
      // Better approach: History tracks *added* chants, but for MVP, let's track the *total count* attributed to that day if we were resetting daily.
      // Actually, standard Japa counters usually keep a lifetime count or a session count.
      // Let's implement: "Daily Total" = Increment logic adds +1 to today's entry.
    } else {
      newHistory.add({'date': today, 'count': 1}); // Start new day with 1 (since we just incremented)
    }
    
    // Wait, if I use the logic "add 1 to today's entry", it's safer against Resets.
    if (index != -1) {
      int currentDaily = newHistory[index]['count'] as int;
      newHistory[index] = {'date': today, 'count': currentDaily + 1};
    }

    // This is slightly divergent from "saving the count". 
    // This implies `state.history` is "History of Daily Increments".
    state = state.copyWith(history: newHistory);
    // Note: _saveState() is called in increment()
  }

  void reset() {
    HapticFeedback.mediumImpact();
    state = state.copyWith(count: 0);
    _saveState();
  }

  void setGoal(int newGoal) {
    state = state.copyWith(goal: newGoal);
    _saveState();
  }

  void toggleZenMode() {
    final next = !state.isZenMode;
    state = state.copyWith(isZenMode: next);
    if (next) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Restoration
    }
    _saveState();
  }

  void toggleMode() {
    state = state.copyWith(isTactileMode: !state.isTactileMode);
    _saveState();
  }
}

final counterProvider = StateNotifierProvider<CounterNotifier, CounterState>((ref) {
  return CounterNotifier();
});
