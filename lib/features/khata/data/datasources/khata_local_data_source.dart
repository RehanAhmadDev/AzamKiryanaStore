import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer_model.dart';
import '../models/khata_entry_model.dart';
import '../../domain/entities/khata_entry_entity.dart';

abstract class KhataLocalDataSource {
  Future<void> addCustomer(CustomerModel customer);
  Future<List<CustomerModel>> getAllCustomers();
  Future<void> addKhataEntry(KhataEntryModel entry);
  Future<List<KhataEntryModel>> getEntriesForCustomer(String customerId);
  Future<void> updateCustomerBalance(String customerId, double newBalance);
  // 🚀 New Delete Methods
  Future<void> deleteKhataEntry(String entryId);
  Future<void> deleteCustomer(String customerId);
}

class KhataLocalDataSourceImpl implements KhataLocalDataSource {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('azam_khata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        type TEXT NOT NULL,
        totalBalance REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE khata_entries (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
  }

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
  }

  @override
  Future<void> addKhataEntry(KhataEntryModel entry) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('khata_entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await _syncBalance(txn, entry.customerId);
    });
  }

  @override
  Future<void> deleteKhataEntry(String entryId) async {
    final db = await database;
    await db.transaction((txn) async {
      final res = await txn.query('khata_entries', columns: ['customerId'], where: 'id = ?', whereArgs: [entryId]);
      if (res.isNotEmpty) {
        String cid = res.first['customerId'] as String;
        await txn.delete('khata_entries', where: 'id = ?', whereArgs: [entryId]);
        await _syncBalance(txn, cid);
      }
    });
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);
  }

  Future<void> _syncBalance(Transaction txn, String customerId) async {
    final entries = await txn.query('khata_entries', where: 'customerId = ?', whereArgs: [customerId]);
    double total = 0.0;
    for (var row in entries) {
      double amt = row['amount'] as double;
      total += (row['type'] == 'gave' ? amt : -amt);
    }
    await txn.update('customers', {'totalBalance': total}, where: 'id = ?', whereArgs: [customerId]);
  }

  @override
  Future<List<KhataEntryModel>> getEntriesForCustomer(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('khata_entries', where: 'customerId = ?', whereArgs: [customerId], orderBy: 'date DESC');
    return List.generate(maps.length, (i) => KhataEntryModel.fromMap(maps[i]));
  }

  @override
  Future<void> updateCustomerBalance(String customerId, double newBalance) async {
    final db = await database;
    await db.update('customers', {'totalBalance': newBalance}, where: 'id = ?', whereArgs: [customerId]);
  }
}