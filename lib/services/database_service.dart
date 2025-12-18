import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'food_entries.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await _createFoodEntriesTable(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToVersion2(db);
    }
  }

  Future<void> _createFoodEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_entries (
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
        createdAt TEXT,
        isFavorite INTEGER DEFAULT 0,
        notificationEnabled INTEGER DEFAULT 0,
        notificationId TEXT
      )
    ''');
    print(' Table food_entries créée avec les nouvelles colonnes');
  }

  Future<void> _migrateToVersion2(Database db) async {
    try {
      
      final columns = await db.rawQuery('PRAGMA table_info(food_entries)');
      final hasNotificationEnabled = columns.any((col) => col['name'] == 'notificationEnabled');
      
      if (!hasNotificationEnabled) {
        
        await db.execute('''
          CREATE TABLE food_entries_new (
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
            createdAt TEXT,
            isFavorite INTEGER DEFAULT 0,
            notificationEnabled INTEGER DEFAULT 0,
            notificationId TEXT
          )
        ''');

        
        await db.execute('''
          INSERT INTO food_entries_new 
          SELECT id, uid, name, category, calories, proteins, carbs, fats, fiber, sugar, 
                 servingSize, servingUnit, mealType, notes, date, createdAt, isFavorite, 
                 0, NULL 
          FROM food_entries
        ''');

        
        await db.execute('DROP TABLE food_entries');
        
        
        await db.execute('ALTER TABLE food_entries_new RENAME TO food_entries');
        
        print(' Migration vers la version 2 réussie');
      }
    } catch (e) {
      print(' Erreur lors de la migration: $e');
      
      await db.execute('DROP TABLE IF EXISTS food_entries');
      await _createFoodEntriesTable(db);
    }
  }


  Future<int> addFoodEntry(FoodEntry foodEntry) async {
    try {
      final db = await database;
      
      
      final columns = await db.rawQuery('PRAGMA table_info(food_entries)');
      print(' Colonnes de la table:');
      for (var col in columns) {
        print('  ${col['name']} - ${col['type']}');
      }
      
      final id = await db.insert(
        'food_entries',
        foodEntry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print(' FoodEntry ajouté avec ID: $id');
      return id;
    } catch (e) {
      print(' Erreur lors de l\'ajout du FoodEntry: $e');
      rethrow;
    }
  }


  Future<List<FoodEntry>> getFoodEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('food_entries');
    return List.generate(maps.length, (i) => FoodEntry.fromMap(maps[i]));
  }

  // Mettez à jour un FoodEntry
  Future<void> updateFoodEntry(FoodEntry foodEntry) async {
    final db = await database;
    await db.update(
      'food_entries',
      foodEntry.toMap(),
      where: 'id = ?',
      whereArgs: [foodEntry.id],
    );
  }

  // Supprimez un FoodEntry
  Future<void> deleteFoodEntry(int id) async {
    final db = await database;
    await db.delete(
      'food_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fermez la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}