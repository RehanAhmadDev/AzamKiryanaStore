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
}

class KhataLocalDataSourceImpl implements KhataLocalDataSource {
  static Database? _database;

  // Database initialization logic
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('azam_khata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Creating tables for Customers and Khata Entries
  Future<void> _createDB(Database db, int version) async {
    // Customers Table
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

    // Khata Entries Table (Foreign Key linked to customers)
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

  // --- CRUD Operations ---

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    final db = await database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    // Transaction ensure karti hai ke entry save ho aur balance update ho sath mein
    await db.transaction((txn) async {
      // 1. Entry save karo
      await txn.insert(
        'khata_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Customer ka current balance get karo aur update karo
      final customerData = await txn.query('customers', where: 'id = ?', whereArgs: [entry.customerId]);
      if (customerData.isNotEmpty) {
        double currentBalance = customerData.first['totalBalance'] as double;
        // Agar gave (DIVE) hai toh lene hain (+ve), agar got (LIYE) hai toh dene hain (-ve)
        double amountImpact = entry.type == EntryType.gave ? entry.amount : -entry.amount;
        double newBalance = currentBalance + amountImpact;

        await txn.update(
          'customers',
          {'totalBalance': newBalance},
          where: 'id = ?',
          whereArgs: [entry.customerId],
        );
      }
    });
  }

  @override
  Future<List<KhataEntryModel>> getEntriesForCustomer(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'khata_entries',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => KhataEntryModel.fromMap(maps[i]));
  }

  @override
  Future<void> updateCustomerBalance(String customerId, double newBalance) async {
    final db = await database;
    await db.update(
      'customers',
      {'totalBalance': newBalance},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }
}