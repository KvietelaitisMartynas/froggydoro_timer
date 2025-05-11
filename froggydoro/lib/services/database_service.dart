import 'package:flutter/material.dart';
import 'package:froggydoro/models/calendar_entry_object.dart';
import 'package:froggydoro/models/timer_object.dart';
import 'package:froggydoro/widgets/dialog_helper.dart';
import 'package:froggydoro/main.dart';  // Import for navigatorKey
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  final String _timersTableName = 'timers';
  final String _timersColumnId = 'timer_id';
  final String _timersColumnName = 'name';
  final String _timersColumnWorkDuration = 'work_duration';
  final String _timersColumnBreakDuration = 'break_duration';
  final String _timersColumnCount = 'count';
  final String _timersColumnIsPicked = 'is_picked';

  final String _calendarEntriesTableName = 'calendar_entries';
  final String _calendarEntriesColumnId = 'entry_id';
  final String _calendarEntriesDate = 'date';
  final String _calendarEntriesDuration = 'duration';
  final String _calendarEntriesType = 'type';
  final String _calendarEntriesStatus = 'status';

  final String _achievementsTableName = 'achievements';
  final String _achievementsColumnId = 'achievement_id';
  final String _achievementsName = 'name';
  final String _achievementsDescription = 'description';
  final String _achievementsIconPath = 'path_to_icon';
  final String _achievementsCriteriaKey = "criteria_key";
  final String _achievementsCriteriaValue = "criteria_value";

  final String _userAchievementsTableName = 'user_achievements';
  final String _userAchievementsColumnId = 'user_achievement_id';
  final String _userAchievementsUnlockDate = 'unlocked_date';

  // Queue to manage achievement popups
  static final List<Map<String, dynamic>> _achievementQueue = [];
  static bool _isShowingAchievement = false;

  // Shows the next achievement in the queue
  static void _showNextAchievement() {
    if (_achievementQueue.isEmpty || _isShowingAchievement) {
      return;
    }

    _isShowingAchievement = true;
    final achievement = _achievementQueue.removeAt(0);

    if (navigatorKey.currentContext != null) {
      TimerDialogsHelper.showAchievementDialog(
        navigatorKey.currentContext!,
        achievement['name'] as String,
        achievement['description'] as String,
        achievement['iconPath'] as String,
        onClose: () {
          _isShowingAchievement = false;
          _showNextAchievement(); // Show next achievement when this one is closed
        },
      );
    }
  }

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'froggydoro.db');

    //await deleteDatabase(path);

    final database = await openDatabase(
      path,
      version: 7, // Increment the version
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_timersTableName (
            $_timersColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_timersColumnName TEXT NOT NULL,
            $_timersColumnWorkDuration INTEGER NOT NULL,
            $_timersColumnBreakDuration INTEGER NOT NULL,
            $_timersColumnCount INTEGER DEFAULT 4,
            $_timersColumnIsPicked INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $_calendarEntriesTableName (
            $_calendarEntriesColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_calendarEntriesDate TEXT NOT NULL,
            $_calendarEntriesDuration INTEGER NOT NULL,
            $_calendarEntriesType TEXT NOT NULL,
            $_calendarEntriesStatus TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_achievementsTableName (
            $_achievementsColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_achievementsName TEXT NOT NULL,
            $_achievementsDescription TEXT NOT NULL,
            $_achievementsIconPath TEXT,
            $_achievementsCriteriaKey TEXT NOT NULL,
            $_achievementsCriteriaValue INTEGER NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE $_userAchievementsTableName (
            $_userAchievementsColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_achievementsColumnId INTEGER NOT NULL,
            $_userAchievementsUnlockDate TEXT NOT NULL,
            FOREIGN KEY ($_achievementsColumnId) REFERENCES $_achievementsTableName($_achievementsColumnId)
          );
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute('''
          CREATE TABLE $_achievementsTableName (
            $_achievementsColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_achievementsName TEXT NOT NULL,
            $_achievementsDescription TEXT NOT NULL,
            $_achievementsIconPath TEXT,
            $_achievementsCriteriaKey TEXT NOT NULL,
            $_achievementsCriteriaValue INTEGER NOT NULL
          );
        ''');

          await db.execute('''
            CREATE TABLE $_userAchievementsTableName (
              $_userAchievementsColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
              $_achievementsColumnId INTEGER NOT NULL,
              $_userAchievementsUnlockDate TEXT NOT NULL,
              FOREIGN KEY ($_achievementsColumnId) REFERENCES $_achievementsTableName($_achievementsColumnId)
            );
          ''');
        }

        if (oldVersion < 6) {
          // Check if calendar table exists and create it only if necessary.
          final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$_calendarEntriesTableName'",
          );
          if (result.isEmpty) {
            await db.execute('''
              CREATE TABLE $_calendarEntriesTableName (
                $_calendarEntriesColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
                $_calendarEntriesDate TEXT NOT NULL,
                $_calendarEntriesDuration INTEGER NOT NULL,
                $_calendarEntriesType TEXT NOT NULL,
                $_calendarEntriesStatus TEXT NOT NULL
              )
            ''');
          }
        }
      },
    );

    return database;
  }

  Future<int> addTimer(
    String name,
    int workDuration,
    int breakDuration, {
    int count = 4,
    int isPicked = 0,
  }) async {
    final db = await database;
    final id = await db.insert(_timersTableName, {
      _timersColumnName: name,
      _timersColumnWorkDuration: workDuration,
      _timersColumnBreakDuration: breakDuration,
      _timersColumnCount: count,
      _timersColumnIsPicked: isPicked,
    });
    return id;
  }

  Future<List<TimerObject>> getTimers() async {
    final db = await database;
    final data = await db.query(_timersTableName);
    //print(data);
    List<TimerObject> timers =
        data
            .map(
              (e) => TimerObject(
                id:
                    e[_timersColumnId]
                        as int, // this retrieves the value from 'timer_id'
                name: e[_timersColumnName] as String,
                workDuration: e[_timersColumnWorkDuration] as int,
                breakDuration: e[_timersColumnBreakDuration] as int,
                count: e[_timersColumnCount] as int,
              ),
            )
            .toList();

    return timers;
  }

  Future<TimerObject?> getPickedTimer() async {
    final db = await database;
    final data = await db.query(
      _timersTableName,
      where: '$_timersColumnIsPicked = ?',
      whereArgs: [1],
    );

    if (data.isNotEmpty) {
      return TimerObject(
        id: data[0][_timersColumnId] as int,
        name: data[0][_timersColumnName] as String,
        workDuration: data[0][_timersColumnWorkDuration] as int,
        breakDuration: data[0][_timersColumnBreakDuration] as int,
        count: data[0][_timersColumnCount] as int,
      );
    }
    return null;
  }

  Future<void> updateTimer(
    int id,
    String name,
    int workDuration,
    int breakDuration, {
    int count = 4,
  }) async {
    final db = await database;
    await db.update(
      _timersTableName,
      {
        _timersColumnName: name,
        _timersColumnWorkDuration: workDuration,
        _timersColumnBreakDuration: breakDuration,
        _timersColumnCount: count,
      },
      where: '$_timersColumnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTimer(int id) async {
    final db = await database;
    await db.delete(
      _timersTableName,
      where: '$_timersColumnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> setPickedTimer(int id) async {
    // Set all timers to is_picked = 0, then set selected one to 1
    final db = await database;

    await db.update(_timersTableName, {_timersColumnIsPicked: 0});

    await db.update(
      _timersTableName,
      {_timersColumnIsPicked: 1},
      where: '$_timersColumnId = ?',
      whereArgs: [id],
    );
  }

  // Achievement methods
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    final db = await database;
    return await db.query(_achievementsTableName);
  }

  Future<List<Map<String, dynamic>>> getUnlockedAchievements() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT a.*, ua.$_userAchievementsUnlockDate 
    FROM $_achievementsTableName a
    JOIN $_userAchievementsTableName ua
    ON a.$_achievementsColumnId = ua.$_achievementsColumnId
  ''');
  }

  Future<void> unlockAchievement(int achievementId) async {
    final db = await database;

    final existing = await db.query(
      _userAchievementsTableName,
      where: '$_achievementsColumnId = ?',
      whereArgs: [achievementId],
    );

    if (existing.isEmpty) {
      await db.insert(_userAchievementsTableName, {
        _achievementsColumnId: achievementId,
        _userAchievementsUnlockDate: DateTime.now().toIso8601String(),
      });
    }
  }

  Future<bool> isAchievementUnlocked(int achievementId) async {
    final db = await database;
    final result = await db.query(
      _userAchievementsTableName,
      where: '$_achievementsColumnId = ?',
      whereArgs: [achievementId],
    );
    return result.isNotEmpty;
  }

  // Add the new methods here
  Future<void> trackPomodoroCompletion(DateTime completionTime) async {
    await checkAndUnlockAchievements(completionTime);
  }

  Future<bool> checkAndUnlockAchievements(DateTime completionTime) async {
    final db = await database;
    final achievements = await getAllAchievements();
    bool achievementUnlocked = false;

    for (var achievement in achievements) {
      final criteriaKey = achievement[_achievementsCriteriaKey] as String;
      final criteriaValue = achievement[_achievementsCriteriaValue] as int;
      final achievementId = achievement[_achievementsColumnId] as int;

      bool shouldUnlock = false;

      // Check based on criteria
      switch (criteriaKey) {
        case 'pomodoros_completed':
          final count = await _getPomodoroCompletionCount();
          shouldUnlock = count >= criteriaValue;
          break;

        case 'pomodoros_in_one_day':
          final count = await _getPomodorosCompletedToday(completionTime);
          shouldUnlock = count >= criteriaValue;
          break;

        case 'days_in_a_row':
          final streak = await calculateStreak();
          shouldUnlock = streak >= criteriaValue;
          break;

        case 'pomodoro_before_9am':
          shouldUnlock = completionTime.hour < 9;
          break;

        case 'pomodoro_after_9pm':
          shouldUnlock = completionTime.hour >= 21;
          break;

        case 'pomodoros_in_one_week':
          final count = await _getPomodorosCompletedThisWeek(completionTime);
          shouldUnlock = count >= criteriaValue;
          break;
      }

      if (shouldUnlock) {
        final isAlreadyUnlocked = await isAchievementUnlocked(achievementId);
        if (!isAlreadyUnlocked) {
          achievementUnlocked = true;
          await unlockAchievement(achievementId);
          
          // Add to queue instead of showing immediately
          _achievementQueue.add({
            'name': achievement[_achievementsName] as String,
            'description': achievement[_achievementsDescription] as String,
            'iconPath': achievement[_achievementsIconPath] as String,
          });
        }
      }
    }
    
    // Start showing achievements if we're not already showing one
    _showNextAchievement();
    
    return achievementUnlocked;
  }

  // Helper methods for achievement criteria
  Future<int> _getPomodoroCompletionCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM $_calendarEntriesTableName 
      WHERE $_calendarEntriesType = 'work' 
      AND $_calendarEntriesStatus = 'completed'
    ''');
    return result.first['count'] as int;
  }

  Future<int> _getPomodorosCompletedToday(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM $_calendarEntriesTableName 
      WHERE $_calendarEntriesType = 'work' 
      AND $_calendarEntriesStatus = 'completed'
      AND $_calendarEntriesDate LIKE '$dateStr%'
    ''');
    return result.first['count'] as int;
  }

  Future<int> _getPomodorosCompletedThisWeek(DateTime date) async {
    final db = await database;
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startStr = weekStart.toIso8601String().split('T')[0];
    final endStr = weekEnd.toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM $_calendarEntriesTableName 
      WHERE $_calendarEntriesType = 'work' 
      AND $_calendarEntriesStatus = 'completed'
      AND $_calendarEntriesDate >= '$startStr' 
      AND $_calendarEntriesDate <= '$endStr'
    ''');
    return result.first['count'] as int;
  }

  Future<int> calculateStreak() async {
    final db = await database;

    final entries = await db.query(
      _calendarEntriesTableName,
      where: '$_calendarEntriesType = ? AND $_calendarEntriesStatus = ?',
      whereArgs: ['work', 'completed'],
      orderBy: '$_calendarEntriesDate DESC',
    );

    int streak = 0;
    DateTime? previousDate;

    for (var entry in entries) {
      final date = DateTime.parse(entry[_calendarEntriesDate] as String);

      if (previousDate == null || previousDate.difference(date).inDays == 1) {
        streak++;
        previousDate = date;
      } else if (previousDate.difference(date).inDays > 1) {
        break;
      }
    }

    return streak;
  }

  /// CALENDAR LOGIC

  Future<void> addCalendarEntry(
    String date,
    int duration,
    String type,
    String status,
  ) async {
    final db = await database;
    await db.insert(_calendarEntriesTableName, {
      _calendarEntriesDate: date,
      _calendarEntriesDuration: duration,
      _calendarEntriesType: type,
      _calendarEntriesStatus: status,
    });
  }

  Future<List<CalendarEntryObject>> getCalendarEntries() async {
    final db = await database;
    final data = await db.query(_calendarEntriesTableName);

    List<CalendarEntryObject> calendarEntries =
        data
            .map(
              (e) => CalendarEntryObject(
                id: e[_calendarEntriesColumnId] as int,
                date: DateTime.parse(e[_calendarEntriesDate] as String),
                duration: e[_calendarEntriesDuration] as int,
                type: e[_calendarEntriesType] as String,
                status: e[_calendarEntriesStatus] as String,
              ),
            )
            .toList();

    return calendarEntries;
  }

  Future<void> deleteCalendarEntry(int id) async {
    final db = await database;
    await db.delete(
      _calendarEntriesTableName,
      where: '$_calendarEntriesColumnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCalendarEntry(
    int id,
    String date,
    int duration,
    String type,
    String status,
  ) async {
    final db = await database;
    await db.update(
      _calendarEntriesTableName,
      {
        _calendarEntriesDate: date,
        _calendarEntriesDuration: duration,
        _calendarEntriesType: type,
        _calendarEntriesStatus: status,
      },
      where: '$_calendarEntriesColumnId = ?',
      whereArgs: [id],
    );
  }

  //Get the entries for calander, by the given date
  Future<List<CalendarEntryObject>> getWorkEntriesForDate(
    String dateString,
  ) async {
    final db = await database;

    final data = await db.query(
      _calendarEntriesTableName,
      where:
          '$_calendarEntriesDate = ? AND ($_calendarEntriesStatus = ? OR $_calendarEntriesStatus = ?)',
      whereArgs: [dateString, 'work', 'completed'],
    );

    return data
        .map(
          (e) => CalendarEntryObject(
            id: e[_calendarEntriesColumnId] as int,
            date: DateTime.parse(e[_calendarEntriesDate] as String),
            duration: e[_calendarEntriesDuration] as int,
            type: e[_calendarEntriesType] as String,
            status: e[_calendarEntriesStatus] as String,
          ),
        )
        .toList();
  }

  // Future<void> checkDatabase() async {
  //   final db = await database;

  //   // Query to count entries
  //   final result = await db.rawQuery('SELECT COUNT(*) FROM $_calendarEntriesTableName');

  //   // Access the result correctly
  //   final count = result.first['COUNT(*)'];  // Get the count of entries

  //   print('Number of entries in database: $count');

  //   // Fetch all entries for inspection
  //   final allEntries = await db.query(_calendarEntriesTableName);
  //   print('All entries in the database: $allEntries');
  // }

  ///A method that populates the database with achievement values.
  Future<void> populateAchievements() async {
    final db = await database;

    final achievements = [
      {
        _achievementsName: 'First Timer',
        _achievementsDescription: 'Complete your first Pomodoro session',
        _achievementsIconPath: 'path/to/first_timer_icon.png',
        _achievementsCriteriaKey: 'pomodoros_completed',
        _achievementsCriteriaValue: 1,
      },
      {
        _achievementsName: 'Focused Five',
        _achievementsDescription: 'Complete 5 Pomodoro sessions in one day',
        _achievementsIconPath: 'path/to/focused_five_icon.png',
        _achievementsCriteriaKey: 'pomodoros_in_one_day',
        _achievementsCriteriaValue: 5,
      },
      {
        _achievementsName: 'Streak Starter',
        _achievementsDescription: 'Use the app 3 days in a row',
        _achievementsIconPath: 'path/to/streak_starter_icon.png',
        _achievementsCriteriaKey: 'days_in_a_row',
        _achievementsCriteriaValue: 3,
      },
      {
        _achievementsName: 'Early Bird',
        _achievementsDescription: 'Complete a Pomodoro before 9 AM',
        _achievementsIconPath: 'path/to/early_bird_icon.png',
        _achievementsCriteriaKey: 'pomodoro_before_9am',
        _achievementsCriteriaValue: 1,
      },
      {
        _achievementsName: 'Night Owl',
        _achievementsDescription: 'Complete a Pomodoro after 9 PM',
        _achievementsIconPath: 'path/to/night_owl_icon.png',
        _achievementsCriteriaKey: 'pomodoro_after_9pm',
        _achievementsCriteriaValue: 1,
      },
      {
        _achievementsName: 'Marathoner',
        _achievementsDescription: 'Complete 25 Pomodoros in one week',
        _achievementsIconPath: 'path/to/marathoner_icon.png',
        _achievementsCriteriaKey: 'pomodoros_in_one_week',
        _achievementsCriteriaValue: 25,
      },
    ];

    for (var achievement in achievements) {
      await db.insert(
        _achievementsTableName,
        achievement,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // Deletes user data from the database
  Future<void> clearUserProgress() async {
    final db = await database;

    // Delete timers associated with the user
    await db.delete(_timersTableName);

    // Delete user-specific achievements
    await db.delete(_userAchievementsTableName);

    // Delete calendar entries
    await db.delete(_calendarEntriesTableName);
  }
}
