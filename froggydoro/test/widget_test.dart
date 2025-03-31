import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:froggydoro/screens/time_settings_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/screens/main_screen.dart';
import 'package:froggydoro/notifications.dart';

class MockUpdateTimer extends Mock {
  void call(
    int workMinutes,
    int workSeconds,
    int breakMinutes,
    int breakSeconds,
  );
}

class MockThemeCall extends Mock {
  void call(ThemeMode themeMode);
}

class MockNotificationsCall extends Mock implements Notifications {
  void call();
}

void main() {
  group('TimeSettingsScreen', () {
    late MockUpdateTimer mockUpdateTimer;

    setUp(() {
      mockUpdateTimer = MockUpdateTimer();
    });

    testWidgets('Load and displays time from shared preferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer.call),
        ),
      );

      expect(find.text('Work Time'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
      expect(find.text('Break Time'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
    });

    testWidgets('Add work time', (tester) async {
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer.call),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pump();

      expect(find.text('30 min'), findsOneWidget);
    });

    testWidgets('Subtracts work time', (tester) async {
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer.call),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left).first);
      await tester.pump();

      expect(find.text('20 min'), findsOneWidget);
    });

    testWidgets('Set timer', (tester) async {
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer.call),
        ),
      );

      await tester.tap(find.text('Set'));
      await tester.pump();

      verify(mockUpdateTimer(25, 0, 5, 0)).called(1);
    });

    testWidgets('Add break time', (tester) async {
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 10,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer.call),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right).last);
      await tester.pump();

      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('Subtracts break time', (tester) async {
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 10,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer.call),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left).last);
      await tester.pump();

      expect(find.text('5 min'), findsOneWidget);
    });
  });

  group('MainScreen', () {
    late MockThemeCall mockThemeCall;
    late MockNotificationsCall mockNotificationsCall;

    setUp(() {
      mockThemeCall = MockThemeCall();
      mockNotificationsCall = MockNotificationsCall();
    });

    testWidgets('Renders MainScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            onThemeModeChanged: mockThemeCall.call,
            notifications: mockNotificationsCall,
          ),
        ),
      );

      expect(find.text('Work Time'), findsOneWidget);
    });

    testWidgets('Timer moves one second', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            onThemeModeChanged: mockThemeCall.call,
            notifications: mockNotificationsCall,
          ),
        ),
      );

      await tester.tap(find.text('Reset'));
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Stop'));

      expect(find.text('24:59'), findsOneWidget);
    });

    testWidgets('Timer resets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            onThemeModeChanged: mockThemeCall.call,
            notifications: mockNotificationsCall,
          ),
        ),
      );

      await tester.tap(find.text('Reset'));
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Stop'));
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
    });
  });

  group('Settings Screen', () {
    late final MockThemeCall mockThemeCall;
    late final MockUpdateTimer mockUpdateTimer;

    setUp(() {
      mockThemeCall = MockThemeCall();
      mockUpdateTimer = MockUpdateTimer();
    });

    testWidgets('Tests if all settings are present', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            updateTimer: mockUpdateTimer.call,
            onThemeModeChanged: mockThemeCall.call,
          ),
        ),
      );

      expect(find.text('General'), findsOneWidget);
    });
  });
}
