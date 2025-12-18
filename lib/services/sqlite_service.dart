// lib/services/sqlite_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_entry.dart';

class SQLiteService {
  static final SQLiteService instance = SQLiteService._internal();
  SQLiteService._internal();

  Database? _db;

  Future<SQLiteService> init() async {
    final path = join(await getDatabasesPath(), 'calorie_app.db');

    _db = await openDatabase(
      path,
      version: 4, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return this;
  }

  /* =======================
     CREATION DB
  ======================== */
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        calories REAL NOT NULL,
        proteins REAL,
        carbs REAL,
        fats REAL,
        fiber REAL,
        sugar REAL,
        servingSize REAL DEFAULT 100.0,
        servingUnit TEXT DEFAULT 'g',
        mealType TEXT,
        notes TEXT,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isFavorite INTEGER DEFAULT 0,
        syncedToFirebase INTEGER DEFAULT 0,
        firebaseId TEXT,
        notificationEnabled INTEGER DEFAULT 0,
        notificationId TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_uid ON food_entries(uid)');
    await db.execute('CREATE INDEX idx_date ON food_entries(date)');
    await db.execute('CREATE INDEX idx_mealType ON food_entries(mealType)');
  }

  /* =======================
     MIGRATIONS
  ======================== */
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final columns =
        await db.rawQuery('PRAGMA table_info(food_entries)');
    bool hasColumn(String name) =>
        columns.any((c) => c['name'] == name);

    if (oldVersion < 2) {
      if (!hasColumn('category')) {
        await db.execute('ALTER TABLE food_entries ADD COLUMN category TEXT');
        await db.execute('ALTER TABLE food_entries ADD COLUMN proteins REAL');
        await db.execute('ALTER TABLE food_entries ADD COLUMN carbs REAL');
        await db.execute('ALTER TABLE food_entries ADD COLUMN fats REAL');
        await db.execute('ALTER TABLE food_entries ADD COLUMN fiber REAL');
        await db.execute('ALTER TABLE food_entries ADD COLUMN sugar REAL');
        await db.execute(
            'ALTER TABLE food_entries ADD COLUMN servingSize REAL DEFAULT 100.0');
        await db.execute(
            "ALTER TABLE food_entries ADD COLUMN servingUnit TEXT DEFAULT 'g'");
        await db.execute('ALTER TABLE food_entries ADD COLUMN mealType TEXT');
        await db.execute('ALTER TABLE food_entries ADD COLUMN notes TEXT');
        await db.execute('ALTER TABLE food_entries ADD COLUMN createdAt TEXT');
        await db.execute(
            'ALTER TABLE food_entries ADD COLUMN isFavorite INTEGER DEFAULT 0');
      }
    }

    if (oldVersion < 3) {
      if (!hasColumn('syncedToFirebase')) {
        await db.execute(
            'ALTER TABLE food_entries ADD COLUMN syncedToFirebase INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE food_entries ADD COLUMN firebaseId TEXT');
      }
    }

    if (oldVersion < 4) {
      if (!hasColumn('notificationEnabled')) {
        await db.execute(
            'ALTER TABLE food_entries ADD COLUMN notificationEnabled INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE food_entries ADD COLUMN notificationId TEXT');
      }
    }
  }

  /* =======================
     CRUD
  ======================== */

  Future<int> insertEntry(FoodEntry e) async {
    final map = e.toMap();
    map.remove('id');
    return await _db!.insert('food_entries', map);
  }

  Future<List<FoodEntry>> getEntriesForUser(String uid) async {
    final rows = await _db!.query(
      'food_entries',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'date DESC',
    );
    return rows.map(FoodEntry.fromMap).toList();
  }

  Future<void> updateEntry(FoodEntry e) async {
    await _db!.update(
      'food_entries',
      e.toMap(),
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<void> deleteEntry(int id) async {
    await _db!.delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }

  /* =======================
     FAVORIS & NOTIFS
  ======================== */

  Future<void> toggleFavorite(int id, bool value) async {
    await _db!.update(
      'food_entries',
      {'isFavorite': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
    
  Future<void> deleteAllEntries(String uid) async {
    await _db!.delete(
      'food_entries',
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  Future<void> toggleNotification(
      int id, bool enabled, String? notificationId) async {
    await _db!.update(
      'food_entries',
      {
        'notificationEnabled': enabled ? 1 : 0,
        'notificationId': notificationId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /* =======================
     STATS
  ======================== */

  Future<Map<String, double>> getStatsBetweenDates(
      String uid, DateTime start, DateTime end) async {
    final rows = await _db!.query(
      'food_entries',
      where: 'uid = ? AND date >= ? AND date < ?',
      whereArgs: [
        uid,
        start.toIso8601String(),
        end.toIso8601String()
      ],
    );

    double calories = 0, proteins = 0, carbs = 0, fats = 0;

    for (final r in rows) {
      final e = FoodEntry.fromMap(r);
      calories += e.calories;
      proteins += e.proteins ?? 0;
      carbs += e.carbs ?? 0;
      fats += e.fats ?? 0;
    }

    return {
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
    };
  }

  Future<void> close() async {
    if (_db?.isOpen ?? false) {
      await _db!.close();
    }
  }
}
