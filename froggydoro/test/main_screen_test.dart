import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}