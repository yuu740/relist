import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cycle.dart';
import '../models/item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('relist.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cycles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycle_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        order_position REAL NOT NULL, -- Menggunakan REAL untuk fleksibilitas di masa depan
        FOREIGN KEY (cycle_id) REFERENCES cycles (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<Cycle> createCycle(Cycle cycle) async {
    final db = await instance.database;
    final id = await db.insert('cycles', cycle.toMap());
    return cycle.copy(id: id);
  }

  Future<List<Cycle>> getAllCycles() async {
    final db = await instance.database;
    final result = await db.query('cycles', orderBy: 'name ASC');
    return result.map((json) => Cycle.fromMap(json)).toList();
  }

  Future<int> updateCycle(Cycle cycle) async {
    final db = await instance.database;
    return db.update(
      'cycles',
      cycle.toMap(),
      where: 'id = ?',
      whereArgs: [cycle.id],
    );
  }

  Future<int> deleteCycle(int id) async {
    final db = await instance.database;
    return await db.delete('cycles', where: 'id = ?', whereArgs: [id]);
  }

  Future<Item> createItem(Item item) async {
    final db = await instance.database;
    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(order_position) as max_order FROM items WHERE cycle_id = ?',
      [item.cycleId],
    );
    final maxOrder =
        (maxOrderResult.first['max_order'] as num?)?.toDouble() ?? 0.0;
    final newItem = item.copy(orderPosition: maxOrder + 1.0);

    final id = await db.insert('items', newItem.toMap());
    return newItem.copy(id: id);
  }

  Future<List<Item>> getItemsByCycleId(int cycleId) async {
    final db = await instance.database;
    final result = await db.query(
      'items',
      where: 'cycle_id = ?',
      whereArgs: [cycleId],
      orderBy: 'order_position ASC',
    );
    return result.map((json) => Item.fromMap(json)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await instance.database;
    return db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> rotateItemToBack(Item item) async {
    final db = await instance.database;
    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(order_position) as max_order FROM items WHERE cycle_id = ?',
      [item.cycleId],
    );
    final maxOrder =
        (maxOrderResult.first['max_order'] as num?)?.toDouble() ?? 0.0;

    await db.update(
      'items',
      {'order_position': maxOrder + 1.0},
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
