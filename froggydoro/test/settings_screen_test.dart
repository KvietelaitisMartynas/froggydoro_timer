/* import 'package:flutter/material.dart';
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
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/screens/settings_screen.dart';
import 'package:froggydoro/screens/time_settings_screen.dart';
import 'package:froggydoro/services/database_service.dart'; // <<< Import Service
import 'package:mockito/annotations.dart'; // <<< Import Annotations
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:froggydoro/notifications.dart'; // Keep if Notifications is mocked

// Import the generated mocks (using the same one as main_screen_test)
// Make sure this path is correct relative to this test file's location
import '../test/main_screen_test.mocks.dart';

// Add the part directive (references the same generated file)
//part '../test/main_screen_test.mocks.dart'; // <<< NOTE: Path adjusted

// --- Annotations for Mock Generation ---
// Re-declare here or ensure main_screen_test.dart covers all needed mocks
@GenerateNiceMocks([
  MockSpec<DatabaseService>(),
  // MockSpec<Notifications>(),
  // MockSpec<SharedPreferences>(),
  MockSpec<TimerObject>(), // Needed if TimeSettingsScreen uses it
])
// --- Manual Mocks for Callbacks (Keep these) ---
class MockUpdateTimerCallback extends Mock {
  void call(
    int workMinutes,
    int workSeconds,
    int breakMinutes,
    int breakSeconds,
    int roundCount,
  );
}

class MockThemeModeChangedCallback extends Mock {
  void call(ThemeMode themeMode);
}

// --- Main Test Function ---
void main() {
  // Optional FFI init - remove if TimeSettingsScreen navigation test relies purely on mocks
  // setUpAll(() {
  //   TestWidgetsFlutterBinding.ensureInitialized(); // Ensure binding first
  //   sqfliteFfiInit();
  //   databaseFactory = databaseFactoryFfi;
  //   print("Sqflite FFI initialized (optional).");
  // });
  // Prefer initializing binding here if needed regardless of FFI
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Screen', () {
    // Use generated and manual mock types
    late MockThemeModeChangedCallback mockThemeModeChangedCallback;
    late MockUpdateTimerCallback mockUpdateTimerCallback;
    late MockDatabaseService mockDatabaseService; // Generated type

    // Helper function to pump the widget with necessary mocks
    Future<void> pumpSettingsScreen(WidgetTester tester) async {
      // Ensure SettingsScreen receives the mocked DatabaseService
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: SettingsScreen(
              updateTimer: mockUpdateTimerCallback.call,
              onThemeModeChanged: mockThemeModeChangedCallback.call,
              databaseService: mockDatabaseService, // <<< Inject Mock DB
            ),
          ),
          // Define routes for navigation testing, passing mocks
          routes: {
            // Define a route name that SettingsScreen might use, or use '/' if replacing home
            // If Navigator.push(MaterialPageRoute(...)) is used, routes might not be needed here,
            // but it's good practice if TimeSettingsScreen also needs DI.
            // We will rely on the MaterialPageRoute builder passing the mock for now.
          },
        ),
      );
      await tester.pumpAndSettle(); // Wait for initState async methods
    }

    setUp(() {
      // Instantiate mocks before each test
      mockThemeModeChangedCallback = MockThemeModeChangedCallback();
      mockUpdateTimerCallback = MockUpdateTimerCallback();
      mockDatabaseService = MockDatabaseService(); // Instantiate generated mock

      SharedPreferences.setMockInitialValues({}); // Clear SharedPreferences
    });

    testWidgets('Tests theme mode change to dark', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      SharedPreferences.setMockInitialValues({
        'themeMode': 'light',
        'isWakeLockEnabled': false,
        'selectedAmbience': 'None',
      });
      await pumpSettingsScreen(tester);

      // Find Theme ListTile, Tap, Find Sheet, Tap Option
      final themeListTileFinder = find.widgetWithText(ListTile, 'Theme Mode');
      expect(themeListTileFinder, findsOneWidget);
      await tester.tap(themeListTileFinder);
      await tester.pumpAndSettle();
      final bottomSheetMaterialFinder = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Material).last,
      );
      expect(bottomSheetMaterialFinder, findsOneWidget);
      final optionFinder = find.descendant(
        of: bottomSheetMaterialFinder,
        matching: find.text('Dark Mode'),
      );
      expect(optionFinder, findsOneWidget);
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Assert
      verify(mockThemeModeChangedCallback.call(ThemeMode.dark)).called(1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), equals('dark'));
      final updatedListTile = tester.widget<ListTile>(themeListTileFinder);
      expect(
        (updatedListTile.subtitle as Row).children.last,
        isA<Text>().having((t) => t.data, 'text data', 'Dark Mode'),
      );
    });

    testWidgets('Tests always on display toggle', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      SharedPreferences.setMockInitialValues({
        'isWakeLockEnabled': false,
        'themeMode': 'system',
        'selectedAmbience': 'None',
      });
      await pumpSettingsScreen(tester);

      // Find SwitchListTile, Tap, Assert State Change
      final wakeLockTileFinder = find.widgetWithText(SwitchListTile, 'Enable');
      expect(wakeLockTileFinder, findsOneWidget);
      expect(tester.widget<SwitchListTile>(wakeLockTileFinder).value, isFalse);
      await tester.tap(wakeLockTileFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(wakeLockTileFinder).value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isWakeLockEnabled'), isTrue);
    });

    testWidgets('Tests ambience settings selection', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      SharedPreferences.setMockInitialValues({
        'selectedAmbience': 'None',
        'themeMode': 'system',
        'isWakeLockEnabled': false,
      });
      await pumpSettingsScreen(tester);

      // Find ListTile, Tap, Find Sheet, Tap Option
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
      final optionFinder = find.descendant(
        of: bottomSheetMaterialFinder,
        matching: find.text('Rain'),
      );
      expect(optionFinder, findsOneWidget);
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Assert
      final updatedListTile = tester.widget<ListTile>(ambienceListTileFinder);
      expect((updatedListTile.subtitle as Text).data, equals('Rain'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedAmbience'), equals('Rain'));
    });

    testWidgets('Tests opening time/break settings', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      SharedPreferences.setMockInitialValues({
        'themeMode': 'system',
        'isWakeLockEnabled': false,
        'selectedAmbience': 'None',
        'workMinutes': 25,
        'breakMinutes': 5,
        'defaultRoundCount': 4,
      });
      // Mock the getTimers call needed by TimeSettingsScreen's FutureBuilder
      when(mockDatabaseService.getTimers()).thenAnswer((_) async {
        return []; // Return empty list
      });
      await pumpSettingsScreen(tester); // Pump SettingsScreen with mock DB

      // Find the Time Settings ListTile
      final timeListTileFinder = find.widgetWithText(
        ListTile,
        'Work/Break Time',
      );
      expect(timeListTileFinder, findsOneWidget);

      // Act: Tap the ListTile to navigate
      await tester.tap(timeListTileFinder);
      // Need pumpAndSettle for navigation animation
      await tester.pumpAndSettle();

      // Assert: Verify TimeSettingsScreen is now present
      // It was built by MaterialPageRoute using the mocks passed down via SettingsScreen
      expect(find.byType(TimeSettingsScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);

      // Optional: Verify getTimers was called by the navigated screen
      verify(mockDatabaseService.getTimers()).called(2);
    });
  });
}
