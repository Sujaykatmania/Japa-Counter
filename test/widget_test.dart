import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japa_counter/main.dart';
import 'package:japa_counter/providers/counter_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({}); // Fresh start

    // Mock Haptics and Sound
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall methodCall) async {
      return null;
    });

    const MethodChannel('xyz.luan/audioplayers')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
  });

  testWidgets('Japa Counter V3 Initial State Test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: JapaCounterApp()));
    await tester.pumpAndSettle();

    // Verify default mantra "Om Namah Shivaya" is loaded
    expect(find.text('OM NAMAH SHIVAYA'), findsOneWidget);

    // Initial counts
    // Expect 2 instances of "0" (Streak Badge + Main Counter)
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('MALA: 0'), findsOneWidget);

    // Goal
    expect(find.text('Goal: 108'), findsOneWidget);
  });

  testWidgets('Increment and Goal Reset Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: JapaCounterApp()));
    await tester.pumpAndSettle();

    // Tap center to increment (in default Tactile mode, there is a circular button)
    // We update HomeScreen to IgnorePointer on text, so tapping center clips should work.
    await tester.tap(find.byType(ClipOval).first);
    await tester.pump();

    // Verify count is 1. Streak is also 1.
    // So "1" should appear twice.
    expect(find.text('1'), findsNWidgets(2));

    // Verify Streak Badge Icon exists
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
  });

  testWidgets('Switching Modes Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: JapaCounterApp()));
    await tester.pumpAndSettle();

    // Go to Settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Toggle Tactile Mode off (Focus Mode)
    // Find switch by text title
    await tester.scrollUntilVisible(find.text('Tactile Mode'), 500);
    await tester.tap(find.text('Tactile Mode'));
    await tester.pumpAndSettle();

    // Go back
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Now in Focus Mode, tapping anywhere should increment
    await tester.tapAt(const Offset(100, 100)); // Tap top left
    await tester.pump();

    // Count is 1 (Streak 1, Count 1)
    expect(find.text('1'), findsNWidgets(2));
  });
}
