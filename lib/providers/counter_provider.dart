import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:japa_counter/models/mantra.dart';

// State Class
class CounterState {
  final List<Mantra> mantras;
  final String? selectedMantraId;
  final int totalLifetimeCount;
  final bool isZenMode;
  final bool isTactileMode;
  final bool isSoundEnabled;
  final bool isHapticsEnabled;
  final bool autoStopOnMala; // V4: New setting
  final bool isMalaCompleted; // V4: New state
  final int currentStreak;
  final String? lastPracticeDate;
  final List<Map<String, dynamic>> history;

  const CounterState({
    this.mantras = const [],
    this.selectedMantraId,
    this.totalLifetimeCount = 0,
    this.isZenMode = false,
    this.isTactileMode = true,
    this.isSoundEnabled = false,
    this.isHapticsEnabled = true,
    this.autoStopOnMala = true, // Default true
    this.isMalaCompleted = false,
    this.currentStreak = 0,
    this.lastPracticeDate,
    this.history = const [],
  });

  Mantra? get activeMantra {
    if (selectedMantraId == null || mantras.isEmpty) return null;
    try {
      return mantras.firstWhere((m) => m.id == selectedMantraId);
    } catch (e) {
      return null;
    }
  }

  CounterState copyWith({
    List<Mantra>? mantras,
    String? selectedMantraId,
    int? totalLifetimeCount,
    bool? isZenMode,
    bool? isTactileMode,
    bool? isSoundEnabled,
    bool? isHapticsEnabled,
    bool? autoStopOnMala,
    bool? isMalaCompleted,
    int? currentStreak,
    String? lastPracticeDate,
    List<Map<String, dynamic>>? history,
  }) {
    return CounterState(
      mantras: mantras ?? this.mantras,
      selectedMantraId: selectedMantraId ?? this.selectedMantraId,
      totalLifetimeCount: totalLifetimeCount ?? this.totalLifetimeCount,
      isZenMode: isZenMode ?? this.isZenMode,
      isTactileMode: isTactileMode ?? this.isTactileMode,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
      autoStopOnMala: autoStopOnMala ?? this.autoStopOnMala,
      isMalaCompleted: isMalaCompleted ?? this.isMalaCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      history: history ?? this.history,
    );
  }
}

// Notifier
class CounterNotifier extends StateNotifier<CounterState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Uuid _uuid = const Uuid();

  // Pastel Colors for Zen Aesthetic
  final List<int> _zenColors = [
    0xFFB0C4DE, // LightSteelBlue
    0xFF98FB98, // PaleGreen
    0xFFFFB6C1, // LightPink
    0xFFE6E6FA, // Lavender
    0xFFF0E68C, // Khaki
    0xFFFFE4B5, // Moccasin
    0xFFAFB42B, // Lime
    0xFF4DB6AC, // Teal Light
  ];

  CounterNotifier() : super(const CounterState()) {
    _loadState();
    try {
      _audioPlayer
          .setSource(AssetSource('sounds/click_sound.wav'))
          .catchError((e) {});
    } catch (_) {}
  }

  static const _keyMantras = 'mantras';
  static const _keySelectedId = 'selected_mantra_id';
  static const _keyLifetime = 'lifetime_count';
  static const _keyZen = 'zen_mode';
  static const _keyTactile = 'tactile_mode';
  static const _keySound = 'sound_enabled';
  static const _keyHaptics = 'haptics_enabled';
  static const _keyAutoStop = 'auto_stop_on_mala'; // V4 Key
  static const _keyStreak = 'current_streak';
  static const _keyLastDate = 'last_practice_date';
  static const _keyHistory = 'history';

  // Legacy Keys for Migration
  static const _legacyCount = 'count';
  static const _legacyGoal = 'goal';
  static const _legacyMala = 'mala_count';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final totalLifetimeCount = prefs.getInt(_keyLifetime) ?? 0;
    final isZen = prefs.getBool(_keyZen) ?? false;
    final isTactile = prefs.getBool(_keyTactile) ?? true;
    final isSound = prefs.getBool(_keySound) ?? false;
    final isHaptics = prefs.getBool(_keyHaptics) ?? true;
    final autoStop = prefs.getBool(_keyAutoStop) ?? true; // V4 Load
    final streak = prefs.getInt(_keyStreak) ?? 0;
    final lastDate = prefs.getString(_keyLastDate);

    final historyString = prefs.getString(_keyHistory);
    List<Map<String, dynamic>> history = [];
    if (historyString != null) {
      try {
        history = List<Map<String, dynamic>>.from(json.decode(historyString));
      } catch (_) {}
    }

    // Load Mantras
    List<Mantra> loadedMantras = [];
    String? selectedId = prefs.getString(_keySelectedId);
    final mantrasString = prefs.getString(_keyMantras);

    if (mantrasString != null) {
      try {
        final List<dynamic> jsonList = json.decode(mantrasString);
        loadedMantras = jsonList.map((j) => Mantra.fromJson(j)).toList();
      } catch (_) {}
    }

    // MIGRATION Check
    if (loadedMantras.isEmpty) {
      // Check for legacy data
      final legacyCount = prefs.getInt(_legacyCount);
      if (legacyCount != null) {
        // Migration needed
        final legacyGoal = prefs.getInt(_legacyGoal) ?? 108;
        final legacyMala = prefs.getInt(_legacyMala) ?? 0;

        final defaultMantra = Mantra(
          id: _uuid.v4(),
          name: "Default Mantra",
          count: legacyCount,
          malaCount: legacyMala,
          goal: legacyGoal,
          color: _getRandomZenColor(),
        );
        loadedMantras.add(defaultMantra);
        selectedId = defaultMantra.id;

        // We do strictly migrate - but leaving old keys is safer for now in case of rollback.
      } else {
        // Fresh Install -> Create one default mantra
        final newMantra = Mantra(
          id: _uuid.v4(),
          name: "Japa",
          count: 0,
          malaCount: 0,
          goal: 108,
          color: _getRandomZenColor(),
        );
        loadedMantras.add(newMantra);
        selectedId = newMantra.id;
      }
    }

    state = CounterState(
      mantras: loadedMantras,
      selectedMantraId: selectedId,
      totalLifetimeCount: totalLifetimeCount,
      isZenMode: isZen,
      isTactileMode: isTactile,
      isSoundEnabled: isSound,
      isHapticsEnabled: isHaptics,
      autoStopOnMala: autoStop,
      currentStreak: streak,
      lastPracticeDate: lastDate,
      history: history,
    );

    if (isZen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final mantrasJson =
        json.encode(state.mantras.map((m) => m.toJson()).toList());

    await prefs.setString(_keyMantras, mantrasJson);
    if (state.selectedMantraId != null) {
      await prefs.setString(_keySelectedId, state.selectedMantraId!);
    }
    await prefs.setInt(_keyLifetime, state.totalLifetimeCount);
    await prefs.setBool(_keyZen, state.isZenMode);
    await prefs.setBool(_keyTactile, state.isTactileMode);
    await prefs.setBool(_keySound, state.isSoundEnabled);
    await prefs.setBool(_keyHaptics, state.isHapticsEnabled);
    await prefs.setBool(_keyAutoStop, state.autoStopOnMala);
    await prefs.setInt(_keyStreak, state.currentStreak);
    if (state.lastPracticeDate != null) {
      await prefs.setString(_keyLastDate, state.lastPracticeDate!);
    }
    await prefs.setString(_keyHistory, json.encode(state.history));
  }

  int _getRandomZenColor() {
    return _zenColors[Random().nextInt(_zenColors.length)];
  }

  void addMantra(String name, int goal) {
    if (name.isEmpty) return;
    final newMantra = Mantra(
      id: _uuid.v4(),
      name: name,
      goal: goal,
      color: _getRandomZenColor(),
    );

    state = state.copyWith(
      mantras: [...state.mantras, newMantra],
      selectedMantraId: newMantra.id,
    );
    _saveState();
  }

  void updateMantra(String id,
      {String? name,
      int? goal,
      String? backgroundPath,
      double? overlayOpacity,
      String? chantText}) {
    final updatedList = state.mantras.map((m) {
      if (m.id == id) {
        return m.copyWith(
          name: name,
          goal: goal,
          backgroundPath: backgroundPath,
          overlayOpacity: overlayOpacity,
          chantText: chantText,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(mantras: updatedList);
    _saveState();
  }

  void deleteMantra(String id) {
    // Prevent deleting if it's the only one (handled in UI too, but safety here)
    if (state.mantras.length <= 1) return;

    final newMantras = state.mantras.where((m) => m.id != id).toList();

    // Logic: If active is deleted, switch to the first one in the new list
    String? newSelectedId = state.selectedMantraId;
    if (state.selectedMantraId == id) {
      if (newMantras.isNotEmpty) {
        newSelectedId = newMantras.first.id;
      }
    }

    state =
        state.copyWith(mantras: newMantras, selectedMantraId: newSelectedId);
    _saveState();
  }

  void selectMantra(String id) {
    state = state.copyWith(selectedMantraId: id);
    _saveState();
  }

  Future<void> increment() async {
    if (state.activeMantra == null) return;
    if (state.isMalaCompleted) {
      return; // Prevent counting if waiting for next mala
    }

    // Update Mantra
    final active = state.activeMantra!;
    int newCount = active.count + 1;
    int newMala = active.malaCount;
    bool malaCompletedNow = false;

    // Check Goal
    if (newCount >= active.goal) {
      if (state.isHapticsEnabled) {
        // Heavy Haptic for completion
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 150),
            () => HapticFeedback.heavyImpact());
      }

      // Play Chime
      if (state.isSoundEnabled) {
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/Chime.wav'),
              mode: PlayerMode.lowLatency);
        } catch (_) {}
      }

      if (state.autoStopOnMala) {
        // V4 Logic: Stop at goal, set completed flag
        newCount = active.goal; // Cap at goal
        malaCompletedNow = true;
      } else {
        // Legacy Logic: Auto-loop
        newCount = 0;
        newMala += 1;
      }
    } else {
      // Normal Increment
      if (state.isHapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
      if (state.isSoundEnabled) {
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/click_sound.wav'),
              mode: PlayerMode.lowLatency);
        } catch (_) {}
      }
    }

    final updatedMantra = active.copyWith(count: newCount, malaCount: newMala);
    final updatedList = state.mantras
        .map((m) => m.id == active.id ? updatedMantra : m)
        .toList();

    // Stats Updates
    int newLifetime = state.totalLifetimeCount + 1;

    // We update streak BEFORE state change to capture logic
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int newStreak = state.currentStreak;
    if (state.lastPracticeDate != today) {
      newStreak = _calculateNewStreak(today);
    }

    state = state.copyWith(
      mantras: updatedList,
      totalLifetimeCount: newLifetime,
      currentStreak: newStreak,
      lastPracticeDate: today,
      isMalaCompleted: malaCompletedNow,
    );

    _saveState();
    _updateDailyHistory();
  }

  // V4: Explicitly start next mala
  void completeMala() {
    if (state.activeMantra == null) return;

    final active = state.activeMantra!;
    // Reset count, increment mala
    final updatedMantra =
        active.copyWith(count: 0, malaCount: active.malaCount + 1);
    final updatedList = state.mantras
        .map((m) => m.id == active.id ? updatedMantra : m)
        .toList();

    state = state.copyWith(mantras: updatedList, isMalaCompleted: false);
    _saveState();
  }

  // V4: Undo/Decrement
  Future<void> decrement() async {
    if (state.activeMantra == null) return;
    if (state.isMalaCompleted) return;

    final active = state.activeMantra!;
    if (active.count <= 0) return;

    if (state.isHapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (state.isSoundEnabled) {
      try {
        await _audioPlayer.stop(); // Click sound for decrement too
        await _audioPlayer.play(AssetSource('sounds/click_sound.wav'),
            mode: PlayerMode.lowLatency);
      } catch (_) {}
    }

    final updatedMantra = active.copyWith(count: active.count - 1);
    final updatedList = state.mantras
        .map((m) => m.id == active.id ? updatedMantra : m)
        .toList();

    // Decrement lifetime count too? Usually yes for "Undo".
    int newLifetime =
        state.totalLifetimeCount > 0 ? state.totalLifetimeCount - 1 : 0;

    // We do NOT decrement streaks usually as they are "days practiced", not "counts"

    state = state.copyWith(
      mantras: updatedList,
      totalLifetimeCount: newLifetime,
    );
    _saveState();
    // Also remove from today's history if possible?
    // For simplicity, we just update stats. History graph might be slight off if not decremented,
    // but _updateDailyHistory is append-only usually.
    // Let's actually decrement history for accuracy.
    _decrementDailyHistory();
  }

  void _decrementDailyHistory() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<Map<String, dynamic>> newHistory = List.from(state.history);
    final index = newHistory.indexWhere((element) => element['date'] == today);

    if (index != -1) {
      int currentDaily = newHistory[index]['count'] as int;
      if (currentDaily > 0) {
        newHistory[index] = {'date': today, 'count': currentDaily - 1};
        state = state.copyWith(history: newHistory);
      }
    }
  }

  int _calculateNewStreak(String today) {
    if (state.lastPracticeDate == null) return 1;
    // final last = DateTime.parse(state.lastPracticeDate!); // Unused
    // final diff = DateTime.now().difference(last).inDays; // Unused

    // DateTime difference in days can be tricky with hours.
    // Better to parse YYYY-MM-DD strings to DateTimes at midnight
    final nowMidnight = DateTime.parse(today);
    final lastMidnight = DateTime.parse(state.lastPracticeDate!);
    final dayDiff = nowMidnight.difference(lastMidnight).inDays;

    if (dayDiff == 1) return state.currentStreak + 1;
    if (dayDiff > 1) return 1;
    return state.currentStreak;
  }

  void _updateDailyHistory() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<Map<String, dynamic>> newHistory = List.from(state.history);
    final index = newHistory.indexWhere((element) => element['date'] == today);

    if (index != -1) {
      int currentDaily = newHistory[index]['count'] as int;
      newHistory[index] = {'date': today, 'count': currentDaily + 1};
    } else {
      newHistory.add({'date': today, 'count': 1});
    }
    state = state.copyWith(history: newHistory);
  }

  // Soft Reset: Count -> 0, Keep Mala
  void resetCurrentCount(String id) {
    if (state.isHapticsEnabled) HapticFeedback.mediumImpact();

    final updatedList = state.mantras.map((m) {
      if (m.id == id) {
        return m.copyWith(count: 0);
      }
      return m;
    }).toList();

    state = state.copyWith(mantras: updatedList);
    _saveState();
  }

  // Hard Reset: Count -> 0, Mala -> 0
  void resetFullHistory(String id) {
    if (state.isHapticsEnabled) HapticFeedback.mediumImpact();

    final updatedList = state.mantras.map((m) {
      if (m.id == id) {
        return m.copyWith(count: 0, malaCount: 0);
      }
      return m;
    }).toList();

    state = state.copyWith(mantras: updatedList);
    _saveState();
  }

  // Legacy/Default reset access
  void reset() {
    if (state.selectedMantraId != null) {
      resetCurrentCount(state.selectedMantraId!);
    }
  }

  void setGoal(int newGoal) {
    if (state.selectedMantraId == null) return;
    final updatedList = state.mantras.map((m) {
      if (m.id == state.selectedMantraId) {
        return m.copyWith(goal: newGoal);
      }
      return m;
    }).toList();
    state = state.copyWith(mantras: updatedList);
    _saveState();
  }

  void toggleZenMode() {
    final next = !state.isZenMode;
    state = state.copyWith(isZenMode: next);
    if (next) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _saveState();
  }

  void toggleMode() {
    state = state.copyWith(isTactileMode: !state.isTactileMode);
    _saveState();
  }

  void toggleSound() {
    state = state.copyWith(isSoundEnabled: !state.isSoundEnabled);
    _saveState();
  }

  void toggleHaptics() {
    state = state.copyWith(isHapticsEnabled: !state.isHapticsEnabled);
    _saveState();
  }

  void toggleAutoStop() {
    state = state.copyWith(autoStopOnMala: !state.autoStopOnMala);
    _saveState();
  }
}

final counterProvider =
    StateNotifierProvider<CounterNotifier, CounterState>((ref) {
  return CounterNotifier();
});
