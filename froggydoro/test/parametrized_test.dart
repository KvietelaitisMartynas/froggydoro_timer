import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:froggydoro/screens/time_settings_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  group('Parametrized tests', () {
    late MockThemeCall mockThemeCall;
    late MockUpdateTimer mockUpdateTimer;

    setUp(() {
      mockThemeCall = MockThemeCall();
      mockUpdateTimer = MockUpdateTimer();
    });

    testWidgets('Tests ambience settings parametrized', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      SharedPreferences.setMockInitialValues({
        'themeMode': 'light',
        'selectedAmbience': 'Test',
      });

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

        await tester.pumpAndSettle();

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

    testWidgets('Creates and displays presets (parameterized)', (tester) async {
      final presetNames = ['Focus Mode', 'Quick Break', 'Long Session'];

      for (var name in presetNames) {
        SharedPreferences.setMockInitialValues({});
        await SharedPreferences.getInstance();

        await tester.pumpWidget(
          MaterialApp(
            home: TimeSettingsScreen(updateTimer: mockUpdateTimer.call),
          ),
        );
        await tester.pumpAndSettle();

        final presetNameField = find.byType(TextField);
        await tester.enterText(presetNameField, name);

        final saveButton = find.widgetWithText(ElevatedButton, 'Save Preset');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(find.text(name), findsOneWidget);
      }
    });
  });
}