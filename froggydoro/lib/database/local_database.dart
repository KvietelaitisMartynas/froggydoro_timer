import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static Database? _database;

  factory LocalDatabase() {
    return _instance;
  }

  String generateUserId() {
    var uuid = Uuid();
    return uuid.v4(); // Generates a unique UUID
  }

  LocalDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('froggydoro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path = join(await getDatabasesPath(), filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("PRAGMA foreign_keys = ON;");

        await db.execute('''
          CREATE TABLE users (
            user_id TEXT PRIMARY KEY, -- UUID instead of auto-increment
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            streak INTEGER DEFAULT 0,
            total_focus_time INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE timers (
            timer_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            work_duration INTEGER NOT NULL DEFAULT 1500,
            break_duration INTEGER NOT NULL DEFAULT 300,
            count INTEGER DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE calendar_entries (
            entry_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            timer_id INTEGER,
            date TEXT NOT NULL,
            focus_duration INTEGER NOT NULL,
            break_duration INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
            FOREIGN KEY (timer_id) REFERENCES timers(timer_id) ON DELETE SET NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE friends (
            user_id TEXT NOT NULL,
            friend_id TEXT NOT NULL,
            status TEXT CHECK( status IN ('pending', 'accepted', 'rejected') ) DEFAULT 'pending',
            requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, friend_id),
            FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
            FOREIGN KEY (friend_id) REFERENCES users(user_id) ON DELETE CASCADE,
            CHECK (user_id != friend_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE achievements (
            achievement_id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL UNIQUE,
            description TEXT NOT NULL,
            criteria TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE user_achievements (
            user_id TEXT NOT NULL,
            achievement_id INTEGER NOT NULL,
            unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, achievement_id),
            FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
            FOREIGN KEY (achievement_id) REFERENCES achievements(achievement_id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<String> insertUser(Map<String, dynamic> userData) async {
    final db = await database;
    String userId = generateUserId(); // Generate UUID for user

    userData['user_id'] = userId;
    await db.insert('users', userData);

    return userId; // Return the generated UUID
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> insertTimer(
    String userId,
    String name,
    int workDuration,
    int breakDuration,
    int count,
  ) async {
    final db = await database;
    await db.insert('timers', {
      'user_id': userId, // Link to user by UUID
      'name': name,
      'work_duration': workDuration,
      'break_duration': breakDuration,
      'count': count,
    });
  }

  Future<List<Map<String, dynamic>>> getTimerByUserId(String userId) async {
    final db = await database;
    return await db.query('timers', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> updateTimer(
    int timerId,
    String name,
    int workDuration,
    int breakDuration,
    int count,
  ) async {
    final db = await database;
    await db.update(
      'timers',
      {
        'name': name,
        'work_duration': workDuration,
        'break_duration': breakDuration,
        'count': count,
      },
      where: 'timer_id = ?',
      whereArgs: [timerId],
    );
  }

  Future<void> deleteTimer(int timerId) async {
    final db = await database;
    await db.delete('timers', where: 'timer_id = ?', whereArgs: [timerId]);
  }
}
