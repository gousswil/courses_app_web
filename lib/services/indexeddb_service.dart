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
}
