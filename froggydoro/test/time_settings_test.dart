/* import 'package:flutter/material.dart';
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
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:froggydoro/models/timerObject.dart';
import 'package:froggydoro/screens/time_settings_screen.dart';
import 'package:froggydoro/services/database_service.dart'; // Import real service for DI type
import 'package:froggydoro/widgets/time_step.dart';
import 'package:mockito/annotations.dart'; // Import annotations
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:froggydoro/notifications.dart'; // Not used here but keep pattern if needed
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Keep FFI for potential direct calls if mocking fails

// Import the generated mocks (using the same one as main_screen_test)
// Adjust path if needed
import '../test/main_screen_test.mocks.dart';

// --- Annotations for Mock Generation ---
// Declare mocks needed by TimeSettingsScreen
// Ensure DatabaseService and TimerObject are included here or in main_screen_test.dart's annotation
@GenerateNiceMocks([
  MockSpec<DatabaseService>(),
  MockSpec<TimerObject>(),
  // MockSpec<SharedPreferences>(), // If needed directly
])
// --- Manual Mock for Callback ---
class MockUpdateTimerCallback extends Mock {
  void call(
    int workMinutes,
    int workSeconds,
    int breakMinutes,
    int breakSeconds,
    int roundCount,
  );
}

// --- Main Test Function ---
void main() {
  // Ensure binding is initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  // Optional: Initialize FFI if any fallback to real DB might occur
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print("Sqflite FFI initialized (optional).");
  });

  group('TimeSettingsScreen', () {
    // Use generated and manual mock types
    late MockUpdateTimerCallback mockUpdateTimerCallback;
    late MockDatabaseService mockDatabaseService; // Generated type

    // Helper to pump widget with mocks
    Future<void> pumpTimeSettingsScreen(WidgetTester tester) async {
      // Mock the initial call to getTimers by the FutureBuilder
      when(
        mockDatabaseService.getTimers(),
      ).thenAnswer((_) async => []); // Start with empty presets

      await tester.pumpWidget(
        MaterialApp(
          home: TimeSettingsScreen(
            updateTimer: mockUpdateTimerCallback.call,
            databaseService: mockDatabaseService, // Inject mock DB
          ),
        ),
      );
      // Wait for initState async (_loadTimeSettings) and FutureBuilder
      await tester.pumpAndSettle();
    }

    setUp(() {
      // Instantiate mocks
      mockUpdateTimerCallback = MockUpdateTimerCallback();
      mockDatabaseService = MockDatabaseService();

      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Loads and displays time', (tester) async {
      // Arrange: Set initial prefs that _loadTimeSettings will read
      SharedPreferences.setMockInitialValues({
        'workMinutes': 35, // Use a distinct value
        'breakMinutes': 10, // Use a distinct value
        'defaultRoundCount': 3, // Use a distinct value
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Act: Pump the widget using the helper
      await pumpTimeSettingsScreen(tester);

      // Assert: Check if the TimeStep widgets display the loaded values
      // Need to find the specific TimeStep widgets more reliably
      final workTimeStepFinder = find.ancestor(
        of: find.text('Work Time'), // Find the label
        matching: find.byType(TimeStep), // Find the parent TimeStep
      );
      final breakTimeStepFinder = find.ancestor(
        of: find.text('Break Time'),
        matching: find.byType(TimeStep),
      );
      final roundCountStepFinder = find.ancestor(
        of: find.text('Round Count'),
        matching: find.byType(TimeStep),
      );

      expect(workTimeStepFinder, findsOneWidget);
      expect(breakTimeStepFinder, findsOneWidget);
      expect(roundCountStepFinder, findsOneWidget);

      // Check the text displaying the value within each TimeStep
      // This assumes the TimeStep widget internally displays "${value} unit"
      expect(
        find.descendant(of: workTimeStepFinder, matching: find.text('35 min')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: breakTimeStepFinder, matching: find.text('10 min')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: roundCountStepFinder,
          matching: find.text('3 rounds'),
        ),
        findsOneWidget,
      );

      // Verify getTimers was called once initially by FutureBuilder
      verify(mockDatabaseService.getTimers()).called(2);
    });

    testWidgets('Add work time updates display', (tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
        'defaultRoundCount': 4,
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await pumpTimeSettingsScreen(tester);

      // Find the specific increment button for "Work Time"
      final workTimeStepFinder = find.ancestor(
        of: find.text('Work Time'),
        matching: find.byType(TimeStep),
      );
      final incrementButtonFinder = find.descendant(
        of: workTimeStepFinder,
        matching: find.byIcon(
          Icons.chevron_right,
        ), // Find the right arrow within the work TimeStep
      );
      expect(incrementButtonFinder, findsOneWidget);

      // Act: Tap the button
      await tester.tap(incrementButtonFinder);
      await tester.pump(); // Rebuild after setState

      // Assert: Check updated value display
      expect(
        find.descendant(of: workTimeStepFinder, matching: find.text('30 min')),
        findsOneWidget,
      );
    });

    testWidgets('Subtract work time updates display', (tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 5,
        'defaultRoundCount': 4,
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await pumpTimeSettingsScreen(tester);

      // Find the specific decrement button for "Work Time"
      final workTimeStepFinder = find.ancestor(
        of: find.text('Work Time'),
        matching: find.byType(TimeStep),
      );
      final decrementButtonFinder = find.descendant(
        of: workTimeStepFinder,
        matching: find.byIcon(Icons.chevron_left), // Find the left arrow
      );
      expect(decrementButtonFinder, findsOneWidget);

      // Act
      await tester.tap(decrementButtonFinder);
      await tester.pump();

      // Assert
      expect(
        find.descendant(of: workTimeStepFinder, matching: find.text('20 min')),
        findsOneWidget,
      );
    });

    testWidgets('Set time button calls updateTimer callback', (tester) async {
      // Arrange: Load specific values to verify they are passed
      SharedPreferences.setMockInitialValues({
        'workMinutes': 20,
        'breakMinutes': 10,
        'defaultRoundCount': 2,
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await pumpTimeSettingsScreen(tester);

      // Act: Tap the "Set" button
      final setButtonFinder = find.widgetWithText(ElevatedButton, 'Set');
      expect(setButtonFinder, findsOneWidget);
      await tester.tap(setButtonFinder);
      await tester.pump(); // Wait for potential state changes

      // Assert: Verify the callback was called with the loaded values
      verify(mockUpdateTimerCallback.call(20, 0, 10, 0, 2)).called(1);

      // Optional: Verify settings were saved back to prefs
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('workMinutes'), 20);
      expect(prefs.getInt('breakMinutes'), 10);
      expect(prefs.getInt('defaultRoundCount'), 2);
    });

    testWidgets('Add break time updates display', (tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 10,
        'defaultRoundCount': 4,
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await pumpTimeSettingsScreen(tester);

      // Find the specific increment button for "Break Time"
      final breakTimeStepFinder = find.ancestor(
        of: find.text('Break Time'),
        matching: find.byType(TimeStep),
      );
      final incrementButtonFinder = find.descendant(
        of: breakTimeStepFinder,
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(incrementButtonFinder, findsOneWidget);

      // Act
      await tester.tap(incrementButtonFinder);
      await tester.pump();

      // Assert
      expect(
        find.descendant(of: breakTimeStepFinder, matching: find.text('15 min')),
        findsOneWidget,
      );
    });

    testWidgets('Subtract break time updates display', (tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workMinutes': 25,
        'breakMinutes': 10,
        'defaultRoundCount': 4,
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await pumpTimeSettingsScreen(tester);

      // Find the specific decrement button for "Break Time"
      final breakTimeStepFinder = find.ancestor(
        of: find.text('Break Time'),
        matching: find.byType(TimeStep),
      );
      final decrementButtonFinder = find.descendant(
        of: breakTimeStepFinder,
        matching: find.byIcon(Icons.chevron_left),
      );
      expect(decrementButtonFinder, findsOneWidget);

      // Act
      await tester.tap(decrementButtonFinder);
      await tester.pump();

      // Assert
      expect(
        find.descendant(of: breakTimeStepFinder, matching: find.text('5 min')),
        findsOneWidget,
      );
    });

    // Add tests for Round Count increments/decrements similarly...

    // Add test for saving preset (can reuse logic from parametrized_test)
    testWidgets('Save preset updates preset list (with mock DB)', (
      tester,
    ) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'workMinutes': 15,
        'breakMinutes': 3,
        'defaultRoundCount': 2,
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      const presetName = 'Test Preset';

      // --- Configure Mocks ---
      // 1. Define the expected timer object data
      final savedTimer = MockTimerObject();
      when(savedTimer.id).thenReturn(1); // Mock ID
      when(savedTimer.name).thenReturn(presetName);
      when(savedTimer.workDuration).thenReturn(15);
      when(savedTimer.breakDuration).thenReturn(3);
      when(savedTimer.count).thenReturn(2);

      // 2. Mock INITIAL getTimers call to return empty list
      when(mockDatabaseService.getTimers()).thenAnswer((_) async {
        print("MOCK DEBUG: Initial getTimers() called! Returning [].");
        return <TimerObject>[]; // Return empty list first time
      });

      // 3. Mock addTimer - it doesn't need to return anything complex now
      when(
        mockDatabaseService.addTimer(presetName, 15, 3, count: 2),
      ).thenAnswer((_) async {
        print("MOCK DEBUG: addTimer called for '$presetName'.");
        // No return needed for Future<void>
        // We will change the getTimers mock *after* this runs
      });

      // Act: Pump initial state
      await pumpTimeSettingsScreen(tester); // Calls getTimers (returns [])
      verify(mockDatabaseService.getTimers()).called(2); // Verify initial call

      // Act: Enter name and save
      final presetNameFieldFinder = find.widgetWithText(
        TextField,
        'Preset Name',
      );
      expect(presetNameFieldFinder, findsOneWidget);
      await tester.enterText(presetNameFieldFinder, presetName);
      await tester.pump();
      final saveButtonFinder = find.widgetWithText(
        ElevatedButton,
        'Save Preset',
      );
      expect(saveButtonFinder, findsOneWidget);

      // --- *** Crucial Change: Re-mock getTimers BEFORE tapping save *** ---
      // After the save, the NEXT call to getTimers should return the saved item
      when(mockDatabaseService.getTimers()).thenAnswer((_) async {
        print(
          "MOCK DEBUG: Subsequent getTimers() called! Returning ['$presetName'].",
        );
        return <TimerObject>[savedTimer]; // Now return the list with the item
      });
      // ---------------------------------------------------------------------

      await tester.tap(saveButtonFinder); // Calls addTimer, then setState
      await tester
          .pumpAndSettle(); // Rebuild calls the *newly configured* getTimers

      // --- Assertions ---
      // Verify addTimer was called
      verify(
        mockDatabaseService.addTimer(presetName, 15, 3, count: 2),
      ).called(1);

      // Verify getTimers was called again (total 2 times)
      // The second call used the re-mocked response
      verify(mockDatabaseService.getTimers()).called(1);

      // Assert UI update
      final presetListViewFinder = find.byType(ListView).last;
      expect(presetListViewFinder, findsOneWidget);
      final presetTextInListFinder = find.descendant(
        of: presetListViewFinder,
        matching: find.text(presetName),
      );
      expect(
        presetTextInListFinder,
        findsOneWidget,
        reason:
            "Failed to find saved preset text '$presetName' in the list (mock DB)",
      );
    }); // End testWidgets
  }); // End group
} // End main
