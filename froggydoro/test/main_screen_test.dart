/* import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/services/database_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/screens/main_screen.dart';
import 'package:froggydoro/notifications.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

class MockDatabaseService extends Mock implements DatabaseService {
  Future<TimerObject> getPickedTimer() async {
    return MockTimerObject();
  }
}

class MockTimerObject extends Mock implements TimerObject {
  @override
  int get workDuration => super.noSuchMethod(
    Invocation.getter(#workDuration),
    returnValue: 25,
    returnValueForMissingStub: 25,
  );

  @override
  int get breakDuration => super.noSuchMethod(
    Invocation.getter(#breakDuration),
    returnValue: 5,
    returnValueForMissingStub: 5,
  );

  @override
  int get count => super.noSuchMethod(
    Invocation.getter(#count),
    returnValue: 4,
    returnValueForMissingStub: 4,
  );
}

void main() {
  setUpAll(() async {
    //TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MainScreen', () {
    late MockThemeCall mockThemeCall;
    late MockNotificationsCall mockNotificationsCall;
    late MockDatabaseService mockDatabaseService;
    late MockTimerObject mockTimerObject;

    setUp(() {
      mockThemeCall = MockThemeCall();
      mockNotificationsCall = MockNotificationsCall();
      mockDatabaseService = MockDatabaseService();
      mockTimerObject = MockTimerObject();

      // Configure the mock TimerObject
      when(mockTimerObject.workDuration).thenReturn(25);
      when(mockTimerObject.breakDuration).thenReturn(5);
      when(mockTimerObject.count).thenReturn(4);

      // Configure the mock DatabaseService to return the mock TimerObject
      when(
        mockDatabaseService.getPickedTimer(),
      ).thenAnswer((_) async => mockTimerObject);
    });

    testWidgets('Renders MainScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            onThemeModeChanged: mockThemeCall.call,
            notifications: mockNotificationsCall,
            databaseService: mockDatabaseService,
          ),
        ),
      );

      await tester.pumpAndSettle();

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
            databaseService: mockDatabaseService,
          ),
        ),
      );

      //await tester.tap(find.text('Reset'));
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(find.text('Stop'));
      await tester.pumpAndSettle();
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
            databaseService: mockDatabaseService,
          ),
        ),
      );

      // Wait for async initialization to complete
      await tester.pumpAndSettle();

      // Start the timer
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 1));

      // Ensure the Stop button is visible and tap it to pause the timer
      await tester.pumpAndSettle();
      expect(find.text('Stop'), findsOneWidget);
      await tester.tap(find.text('Stop'));

      // Ensure the Reset button is visible and tap it
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsOneWidget);
      await tester.tap(find.text('Reset'));

      // Verify the timer resets to 25:00
      await tester.pumpAndSettle();
      expect(find.text('25:00'), findsOneWidget);
    });
  });
}
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/services/database_service.dart';
import 'package:mockito/annotations.dart'; // Import annotations
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:froggydoro/screens/main_screen.dart';
import 'package:froggydoro/notifications.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'main_screen_test.mocks.dart';

//part 'main_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Notifications>(),
  MockSpec<DatabaseService>(),
  MockSpec<TimerObject>(),
  MockSpec<
    SharedPreferences
  >(), // Mock SharedPreferences as well if needed directly
])
class MockThemeCall extends Mock {
  void call(ThemeMode themeMode);
}

// --- Main Test Function ---
void main() {
  // Initialize sqflite_common_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MainScreen', () {
    late MockThemeCall mockThemeCall;
    late MockNotifications mockNotificationsCall;
    late MockDatabaseService mockDatabaseService;
    late MockTimerObject mockTimerObject;
    // Keep MockSharedPreferences if you need to interact with it directly in tests
    // late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      mockThemeCall = MockThemeCall();
      mockNotificationsCall = MockNotifications();
      mockDatabaseService = MockDatabaseService();
      mockTimerObject = MockTimerObject();
      // mockSharedPreferences = MockSharedPreferences();

      // --- Configure Mocks ---

      // Configure the mock TimerObject properties
      // Use when().thenReturn() for simple value returns
      when(mockTimerObject.workDuration).thenReturn(25);
      when(mockTimerObject.breakDuration).thenReturn(5);
      when(mockTimerObject.count).thenReturn(4);
      // Add other properties if MainScreen uses them (e.g., name, id)
      when(mockTimerObject.name).thenReturn('Default Timer');
      when(mockTimerObject.id).thenReturn(1);

      // Configure the mock DatabaseService ***CORRECTLY***
      // Use when().thenAnswer() for async methods
      when(
        mockDatabaseService.getPickedTimer(),
      ).thenAnswer((_) async => mockTimerObject); // Correct way to mock async

      SharedPreferences.setMockInitialValues({
        'theme': 'light', // Example if theme is loaded from prefs
      });
    });

    // Helper function to build the widget tree
    Future<void> pumpMainScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            onThemeModeChanged: mockThemeCall, // Pass the mock function
            notifications: mockNotificationsCall, // Pass the mock object
            databaseService: mockDatabaseService, // Pass the mock service
          ),
        ),
      );
      // Wait for async operations like getPickedTimer() to complete
      await tester.pumpAndSettle();
    }

    testWidgets('Renders MainScreen and loads initial timer', (tester) async {
      // Arrange: Set surface size for consistent layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Act: Pump the widget
      await pumpMainScreen(tester);

      // Assert: Verify initial state based on mocked DatabaseService
      expect(find.text('Work Time'), findsOneWidget);
      expect(
        find.text('25:00'),
        findsOneWidget,
      ); // Check initial time from mockTimerObject
      expect(find.text('Start'), findsOneWidget);
      //expect(find.text('Reset'), findsOneWidget);

      // Verify that getPickedTimer was called
      verify(mockDatabaseService.getPickedTimer()).called(1);
    });

    testWidgets('Timer starts, runs for one second, and stops', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await pumpMainScreen(tester);

      // Verify initial state
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      // Act: Start the timer
      await tester.tap(find.text('Start'));
      await tester.pump(); // Let the state update to show 'Stop'

      // Assert: Check if 'Stop' button appears
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Start'), findsNothing); // Start button should be gone

      // Act: Advance time by 1 second
      await tester.pump(const Duration(seconds: 1));

      // Assert: Check if time updated
      expect(find.text('24:59'), findsOneWidget);
      expect(find.text('25:00'), findsNothing); // Original time should be gone

      // Act: Stop the timer
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle(); // Let state update and settle

      // Assert: Check if 'Start' reappears and time remains paused
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);
      expect(find.text('24:59'), findsOneWidget);

      // Act: Pump again to ensure timer isn't running
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.text('24:59'),
        findsOneWidget,
      ); // Time should not have changed
    });

    testWidgets('Timer resets after starting and stopping', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await pumpMainScreen(tester);

      // Verify initial state
      expect(find.text('25:00'), findsOneWidget);

      // Act: Start the timer
      await tester.tap(find.text('Start'));
      await tester.pump(); // Update state to show 'Stop'
      await tester.pump(const Duration(seconds: 2)); // Run for 2 seconds

      // Assert: Check time update and 'Stop' button
      expect(find.text('24:58'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);

      // Act: Stop the timer
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle(); // Settle state changes

      // Assert: Check if stopped correctly
      expect(find.text('Start'), findsOneWidget);
      expect(
        find.text('Reset'),
        findsOneWidget,
      ); // Reset should be visible when stopped
      expect(find.text('24:58'), findsOneWidget);

      // Act: Reset the timer
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle(); // Settle state changes after reset

      // Assert: Verify the timer resets to initial work duration
      expect(find.text('25:00'), findsOneWidget); // Back to initial time
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Reset'), findsNothing);
      expect(find.text('Stop'), findsNothing); // Stop should be hidden

      verify(
        mockDatabaseService.getPickedTimer(),
      ).called(1); // Should only be called once during setup
    });
  });
}
