import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/screens/settings_screen.dart';
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
}