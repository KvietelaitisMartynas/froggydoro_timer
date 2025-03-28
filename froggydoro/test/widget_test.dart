import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/screens/time_settings_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUpdateTimer extends Mock {
  void call(int workMinutes, int workSeconds, int breakMinutes, int breakSeconds);
}

void main() {
  group('TimeSettingsScreen', () {
    late MockUpdateTimer mockUpdateTimer;

    setUp(() {
      mockUpdateTimer = MockUpdateTimer();
    });

    testWidgets('Load and displays time from shared preferences', (tester) async {
      // Simulate SharedPreferences
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer),
        ),
      );

      // Verify the initial work and break time values
      expect(find.text('Work Time'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
      expect(find.text('Break Time'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
    });

    testWidgets('Add work time', (tester) async {
      // Simulate SharedPreferences
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer),
        ),
      );

      // Tap on the increment button for work time
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pump();

      // Verify that the work time has increased by 5 minutes
      expect(find.text('30 min'), findsOneWidget);
    });

    testWidgets('Subtracts work time', (tester) async {
      // Simulate SharedPreferences
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer),
        ),
      );

      // Tap on the decrement button for work time
      await tester.tap(find.byIcon(Icons.chevron_left).first);
      await tester.pump();

      // Verify that the work time has decreased by 5 minutes
      expect(find.text('20 min'), findsOneWidget);
    });

    testWidgets('Set timer', (tester) async {
      // Simulate SharedPreferences
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer),
        ),
      );

      // Tap on the "Set" button
      await tester.tap(find.text('Set'));
      await tester.pump();

      // Verify that the updateTimer function was called with correct values
      verify(mockUpdateTimer(25, 0, 5, 0)).called(1);
    });

    testWidgets('Add break time', (tester) async {
      // Simulate SharedPreferences
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 10,
      });

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer),
        ),
      );

      // Tap on the increment button for work time
      await tester.tap(find.byIcon(Icons.chevron_right).last);
      await tester.pump();

      // Verify that the work time has increased by 5 minutes
      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('Subtracts break time', (tester) async {
      // Simulate SharedPreferences
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 10,
      });

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer),
        ),
      );

      // Tap on the decrement button for work time
      await tester.tap(find.byIcon(Icons.chevron_left).last);
      await tester.pump();

      // Verify that the work time has decreased by 5 minutes
      expect(find.text('5 min'), findsOneWidget);
    });
  });
}

