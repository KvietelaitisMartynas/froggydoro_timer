import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:froggydoro/screens/time_settings_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/screens/main_screen.dart';
import 'package:froggydoro/notifications.dart';
import 'package:froggydoro/utils.dart';

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
    late MockThemeCall mockThemeCall;
    late MockUpdateTimer mockUpdateTimer;

    setUp(() {
      mockThemeCall = MockThemeCall();
      mockUpdateTimer = MockUpdateTimer();
    });

    testWidgets('Tests theme mode change to dark', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      SharedPreferences.setMockInitialValues({'themeMode': 'light'});
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SettingsScreen(
              updateTimer: mockUpdateTimer.call,
              onThemeModeChanged: mockThemeCall.call,
            ),
          ),
        ),
      );

      expect(find.text('Theme Settings'), findsOneWidget);
      await tester.tap(find.text('Theme Mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      verify(mockThemeCall.call(ThemeMode.dark)).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), equals('dark'));
    });

    testWidgets('Tests always on display', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      SharedPreferences.setMockInitialValues({'isWakeLockEnabled': false});

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SettingsScreen(
              updateTimer: mockUpdateTimer.call,
              onThemeModeChanged: mockThemeCall.call,
            ),
          ),
        ),
      );

      expect(find.text('Always on display'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final switchWidgetAfter = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidgetAfter.value, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isWakeLockEnabled'), isTrue);
    });

    testWidgets('Tests ambience settings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      SharedPreferences.setMockInitialValues({'ambientSound': 'None'});

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SettingsScreen(
              updateTimer: mockUpdateTimer.call,
              onThemeModeChanged: mockThemeCall.call,
            ),
          ),
        ),
      );

      expect(find.text('Ambience Settings'), findsOneWidget);
      expect(find.text('Ambient Sounds'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);

      await tester.tap(find.text('Ambient Sounds'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rain'));
      await tester.pumpAndSettle();

      expect(find.text('Rain'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedAmbience'), equals('Rain'));
    });

    testWidgets('Tests opening time/break settings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SettingsScreen(
              updateTimer: mockUpdateTimer.call,
              onThemeModeChanged: mockThemeCall.call,
            ),
          ),
        ),
      );

      expect(find.text('Work/Break Time'), findsOneWidget);

      await tester.tap(find.text('Work/Break Time'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeSettingsScreen), findsOneWidget);
    });
  });

  group('Parametrized tests', () {
    late MockThemeCall mockThemeCall;
    late MockUpdateTimer mockUpdateTimer;

    setUp(() {
      mockThemeCall = MockThemeCall();
      mockUpdateTimer = MockUpdateTimer();
    });

    testWidgets('Tests ambience settings parametrized', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      final ambienceSettings = ['None', 'Bonfire', 'Chirping', 'Rain', 'River'];

      for (final ambience in ambienceSettings) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: SettingsScreen(
                updateTimer: mockUpdateTimer.call,
                onThemeModeChanged: mockThemeCall.call,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Ambient Sounds'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(ambience));
        await tester.pumpAndSettle();

        expect(find.text(ambience), findsOneWidget);
      }
    });

    testWidgets('Format time test parametrized', (tester) async {
        final testCases = <int, String>{
          0: '00:00',
          1: '00:01',
          59: '00:59',
          600: '10:00',
          3599: '59:59',
        };

        testCases.forEach((input, expected) {
          expect(formatTime(input), expected);
        });
    });

    testWidgets('Tests theme mode change parametrized', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      final themeSettings = ['Light Mode', 'Dark Mode', 'Follow System'];

      for (final theme in themeSettings) {
        SharedPreferences.setMockInitialValues({'themeMode': 'light'});
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: SettingsScreen(
                updateTimer: mockUpdateTimer.call,
                onThemeModeChanged: mockThemeCall.call,
              ),
            ),
          ),
        );

        expect(find.text('Theme Settings'), findsOneWidget);
        await tester.tap(find.text('Theme Mode'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(theme).last);
        await tester.pumpAndSettle();

        if (theme == 'Light Mode') {
          verify(mockThemeCall.call(ThemeMode.light)).called(1);
        } else if (theme == 'Dark Mode') {
          verify(mockThemeCall.call(ThemeMode.dark)).called(1);
        } else if (theme == 'Follow System') {
          verify(mockThemeCall.call(ThemeMode.system)).called(1);
        }

        final prefs = await SharedPreferences.getInstance();
        if (theme == 'Light Mode') {
          expect(prefs.getString('themeMode'), equals('light'));
        } else if (theme == 'Dark Mode') {
          expect(prefs.getString('themeMode'), equals('dark'));
        } else if (theme == 'Follow System') {
          expect(prefs.getString('themeMode'), equals('system'));
        }
      }
    });

  });
}
