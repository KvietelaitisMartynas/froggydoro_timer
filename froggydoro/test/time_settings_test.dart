import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/screens/time_settings_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/notifications.dart';

class MockUpdateTimer extends Mock {
  void call(
    int workMinutes,
    int workSeconds,
    int breakMinutes,
    int breakSeconds,
    int roundCount,
  );
}

class MockThemeCall extends Mock {
  void call(ThemeMode themeMode);
}

class MockNotificationsCall extends Mock implements Notifications {
  void call();
}

class MockSharedPreferences extends Mock implements SharedPreferences {
  @override
  Future<bool> setString(String key, String value) async {
    return true;
  }

  @override
  String? getString(String key) {
    return 'light';
  }
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
        'workMinutes': 40,
        'breakMinutes': 5,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: (mockUpdateTimer.call)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Work Time'), findsOneWidget);
      expect(find.text('40 min'), findsOneWidget);
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

      verify(mockUpdateTimer(25, 0, 5, 0, 4)).called(1);
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

      await tester.tap(find.byIcon(Icons.chevron_right).at(1));
      await tester.pump();

      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('Subtract break time', (tester) async {
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 10,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(updateTimer: mockUpdateTimer.call),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left).at(1));
      await tester.pump();

      expect(find.text('5 min'), findsOneWidget);
    });
  });
}