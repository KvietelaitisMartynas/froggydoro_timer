import 'package:froggydoro/models/timerObject.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  final String _timersTableName = 'timers';
  final String _timersColumnId = 'timer_id';
  final String _timersColumnUserId = 'user_id';
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
      version: 5, // Increment the version
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
    print(data);
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
}
