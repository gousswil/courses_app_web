import 'dart:typed_data';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';

class IndexedDbService {
  static const _dbName = 'courses_db';
  static const _storeName = 'images';

  late Database _db;

  Future<void> init() async {
    final idbFactory = idbFactoryBrowser;
    _db = await idbFactory.open(_dbName, version: 1,
        onUpgradeNeeded: (VersionChangeEvent e) {
      final db = e.database;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
      if (!db.objectStoreNames.contains('expenses')) {
        db.createObjectStore('expenses', autoIncrement: true);
      }

    });
  }

  Future<void> saveImage(String id, Uint8List bytes) async {
    final txn = _db.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    await store.put(bytes, id);
    await txn.completed;
  }

  Future<Uint8List?> getImage(String id) async {
    final txn = _db.transaction(_storeName, idbModeReadOnly);
    final store = txn.objectStore(_storeName);
    final result = await store.getObject(id) as Uint8List?;
    await txn.completed;
    return result;
  }

  Future<void> saveExpense(Map<String, dynamic> expense) async {
      final db = await _db;
      final txn = db.transaction('expenses', 'readwrite');
      final store = txn.objectStore('expenses');
      await store.add(expense);
      await txn.completed;
    }

    Future<List<Map<String, dynamic>>> getAllExpenses() async {
      final db = await _db;
      final txn = db.transaction('expenses', 'readonly');
      final store = txn.objectStore('expenses');
      final records = await store.getAll();
      return records.cast<Map<String, dynamic>>();
    }


}
