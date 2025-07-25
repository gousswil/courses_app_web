import 'dart:html';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:indexed_db';

class IndexedDbService {
  static const _dbName = 'courses_app_db';
  static const _dbVersion = 1;
  static const _imageStore = 'images';
  static const _expenseStore = 'expenses';
  static const String imageStoreName = 'images';
  static const String expenseStoreName = 'expenses';

  Database? _database;

  Future<void> init() async {
    if (_database != null) return;

    _database = await window.indexedDB!.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (VersionChangeEvent e) {
        final db = (e.target as Request).result as Database;

        if (!db.objectStoreNames!.contains(_imageStore)) {
          db.createObjectStore(_imageStore);
        }

        if (!db.objectStoreNames!.contains(_expenseStore)) {
          db.createObjectStore(_expenseStore, autoIncrement: true);
        }
      },
    );
  }

  Future<void> saveImage(String id, Uint8List data) async {
    final txn = _database!.transaction(_imageStore, 'readwrite');
    final store = txn.objectStore(_imageStore);
    await store.put(data, id);
    await txn.completed;
  }

  Future<Uint8List?> getImage(String id) async {
    final txn = _database!.transaction(_imageStore, 'readonly');
    final store = txn.objectStore(_imageStore);
    return await store.getObject(id) as Uint8List?;
  }

  Future<void> saveExpense(Map<String, dynamic> expense) async {
    final txn = _database!.transaction(_expenseStore, 'readwrite');
    final store = txn.objectStore(_expenseStore);
    await store.add(expense);
    await txn.completed;
  }

    Future<List<Map<String, dynamic>>> getAllExpenses() async {
        try {
          final txn = _database!.transaction(_expenseStore, 'readonly');
          final store = txn.objectStore(_expenseStore);
          
          final expenses = <Map<String, dynamic>>[];
          
          await for (final cursor in store.openCursor(autoAdvance: false)) {
            if (cursor.value != null) {
              expenses.add(cursor.value as Map<String, dynamic>);
            }
            cursor.next();
          }
          
          return expenses;
        } catch (e) {
          print('Erreur dans getAllExpenses: $e');
          return [];
        }
      }
    Future<void> clearAll() async {
    final txn1 = _database!.transaction(_expenseStore, 'readwrite');
    await txn1.objectStore(_expenseStore).clear();
    await txn1.completed;

    final txn2 = _database!.transaction(_imageStore, 'readwrite');
    await txn2.objectStore(_imageStore).clear();
    await txn2.completed;
  }

    Future<void> addExpense(Map<String, dynamic> expense) async {
      if (_database == null) {
        throw Exception('IndexedDB non initialisé');
      }
      final txn = _database!.transaction(expenseStoreName, 'readwrite');

      final store = txn.objectStore(expenseStoreName);
      await store.add(expense);
      await txn.completed;
    }

}
