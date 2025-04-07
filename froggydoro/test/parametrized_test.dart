/* import 'package:flutter/material.dart';
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
} */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:froggydoro/screens/time_settings_screen.dart';
import 'package:froggydoro/services/database_service.dart'; // Import real service for type
import 'package:froggydoro/models/timerObject.dart'; // Import TimerObject model
import 'package:mockito/annotations.dart'; // <<< Import annotations
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/notifications.dart';
import 'package:froggydoro/utils.dart'; // Assuming formatTime is here
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Import the generated mocks file (will be created by build_runner)
import 'parametrized_test.mocks.dart';

// Add the part directive for the generated file
//part 'parametrized_test.mocks.dart';

// --- Annotations for Mock Generation ---
@GenerateNiceMocks([
  MockSpec<DatabaseService>(),
  MockSpec<TimerObject>(),
  // Add others if needed later, e.g., Notifications, SharedPreferences
  // MockSpec<Notifications>(),
  // MockSpec<SharedPreferences>(),
])
// --- Manual Mocks for Callbacks (Keep these) ---
// Mock for the updateTimer callback signature
class MockUpdateTimerCallback extends Mock {
  void call(
    int workMinutes,
    int workSeconds,
    int breakMinutes,
    int breakSeconds,
    int roundCount,
  );
}

// Mock for the onThemeModeChanged callback signature
class MockThemeModeChangedCallback extends Mock {
  void call(ThemeMode themeMode);
}

// --- Test Main ---
void main() {
  // Initialize FFI (keep if TimeSettingsScreen might still use DatabaseService.instance internally,
  // or if other tests need it. Remove if ALL DB access is mocked).
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // --- Unit test group for utility functions ---
  group('Utility Function Tests', () {
    test('formatTime utility formats correctly', () {
      // ... (formatTime test remains the same) ...
      final testCases = <int, String>{
        0: '00:00',
        1: '00:01',
        59: '00:59',
        60: '01:00',
        600: '10:00',
        3599: '59:59',
        3600: '60:00',
      };
      testCases.forEach((input, expected) {
        expect(formatTime(input), expected, reason: 'Input: $input');
      });
    });
  });

  // --- Widget test group for parametrized tests ---
  group('Parametrized Widget tests', () {
    // Declare mocks using manual and generated types
    late MockThemeModeChangedCallback mockThemeModeChangedCallback;
    late MockUpdateTimerCallback mockUpdateTimerCallback;
    late MockDatabaseService mockDatabaseService; // Use generated mock

    setUp(() {
      // Instantiate mocks
      mockThemeModeChangedCallback = MockThemeModeChangedCallback();
      mockUpdateTimerCallback = MockUpdateTimerCallback();
      mockDatabaseService = MockDatabaseService(); // Instantiate generated mock

      SharedPreferences.setMockInitialValues({});
    });

    // --- Ambience Test (remains largely the same, using manual callback mocks) ---
    testWidgets('Tests ambience settings selection', (tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'themeMode': 'system',
        'isWakeLockEnabled': false,
        'selectedAmbience': 'None',
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      final ambienceOptions = ['None', 'Bonfire', 'Chirping', 'Rain', 'River'];

      for (final ambience in ambienceOptions) {
        // Pump widget, passing the .call method of manual mocks
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: Scaffold(
              body: SettingsScreen(
                updateTimer: mockUpdateTimerCallback.call, // Use .call
                onThemeModeChanged:
                    mockThemeModeChangedCallback.call, // Use .call
                databaseService: mockDatabaseService, // Pass mock instance
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find ListTile, tap, find BottomSheet, find option, tap
        final ambienceListTileFinder = find.widgetWithText(
          ListTile,
          'Ambient Sounds',
        );
        expect(ambienceListTileFinder, findsOneWidget);
        await tester.tap(ambienceListTileFinder);
        await tester.pumpAndSettle();
        final bottomSheetMaterialFinder = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Material).last,
        );
        expect(bottomSheetMaterialFinder, findsOneWidget);
        final ambienceOptionFinder = find.descendant(
          of: bottomSheetMaterialFinder,
          matching: find.text(ambience),
        );
        expect(ambienceOptionFinder, findsOneWidget);
        await tester.tap(ambienceOptionFinder);
        await tester.pumpAndSettle();

        // Assertions
        final updatedAmbienceListTile = tester.widget<ListTile>(
          ambienceListTileFinder,
        );
        expect(
          (updatedAmbienceListTile.subtitle as Text).data,
          equals(ambience),
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selectedAmbience'), equals(ambience));
      }
    });

    // --- Theme Test (remains largely the same, using manual callback mocks) ---
    testWidgets('Tests theme mode change and callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      final themeSettings = <String, dynamic>{
        'Light Mode': {'mode': ThemeMode.light, 'pref': 'light'},
        'Dark Mode': {'mode': ThemeMode.dark, 'pref': 'dark'},
        'Follow System': {'mode': ThemeMode.system, 'pref': 'system'},
      };

      for (final themeName in themeSettings.keys) {
        final themeData = themeSettings[themeName]!;
        final expectedMode = themeData['mode'] as ThemeMode;
        final expectedPref = themeData['pref'] as String;

        // Arrange
        reset(mockThemeModeChangedCallback); // Reset the manual mock
        SharedPreferences.setMockInitialValues({
          'themeMode': 'system' /* other prefs */,
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system,
            home: Scaffold(
              body: SettingsScreen(
                updateTimer: mockUpdateTimerCallback.call, // Use .call
                onThemeModeChanged:
                    mockThemeModeChangedCallback.call, // Use .call
                databaseService: mockDatabaseService, // Pass mock instance
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find ListTile, tap, find BottomSheet, find option, tap
        final themeListTileFinder = find.widgetWithText(ListTile, 'Theme Mode');
        expect(themeListTileFinder, findsOneWidget);
        await tester.tap(themeListTileFinder);
        await tester.pumpAndSettle();
        final bottomSheetMaterialFinder = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Material).last,
        );
        expect(bottomSheetMaterialFinder, findsOneWidget);
        final themeOptionFinder = find.descendant(
          of: bottomSheetMaterialFinder,
          matching: find.text(themeName),
        );
        expect(themeOptionFinder, findsOneWidget);
        await tester.tap(themeOptionFinder);
        await tester.pumpAndSettle();

        // Assertions
        // Verify the manual callback mock's .call method
        verify(mockThemeModeChangedCallback.call(expectedMode)).called(1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('themeMode'), equals(expectedPref));
        final updatedThemeListTile = tester.widget<ListTile>(
          themeListTileFinder,
        );
        final subtitleText =
            (updatedThemeListTile.subtitle as Row).children.last as Text;
        expect(subtitleText.data, equals(themeName));
      }
    });
  }); // End group
} // End main
