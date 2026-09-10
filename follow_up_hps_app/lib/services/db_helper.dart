import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/vital_sign.dart';
import '../models/intake_output.dart';
import '../models/doctor_order.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hps_followup_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients (
            docNo INTEGER PRIMARY KEY,
            patNo TEXT,
            patName TEXT,
            doctorName TEXT,
            roomNo TEXT,
            bedNo TEXT,
            age TEXT,
            gender TEXT,
            admissionDate TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE vitals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            docNo INTEGER,
            time TEXT,
            date TEXT,
            sysBp REAL,
            diaBp REAL,
            pulse REAL,
            temp REAL,
            resp REAL,
            o2Sat REAL,
            painScore INTEGER,
            position TEXT,
            remarks TEXT,
            isSynced INTEGER DEFAULT 0,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE intake_output (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            docNo INTEGER,
            category TEXT,
            typeName TEXT,
            amount REAL,
            time TEXT,
            date TEXT,
            notes TEXT,
            isSynced INTEGER DEFAULT 0,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE doctor_orders (
            id INTEGER PRIMARY KEY,
            docNo INTEGER,
            itemCode TEXT,
            itemName TEXT,
            category TEXT,
            dosage TEXT,
            frequency TEXT,
            doctorName TEXT,
            orderDate TEXT,
            isExecuted INTEGER DEFAULT 0,
            executedAt TEXT,
            executedBy TEXT,
            executionNotes TEXT,
            isSynced INTEGER DEFAULT 1
          )
        ''');
      },
    );
  }

  // --- Patients Cache ---
  static Future<void> savePatient(Patient patient) async {
    final db = await database;
    await db.insert('patients', patient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Patient?> getPatient(int docNo) async {
    final db = await database;
    final maps = await db.query('patients', where: 'docNo = ?', whereArgs: [docNo]);
    if (maps.isNotEmpty) return Patient.fromJson(maps.first);
    return null;
  }

  // --- Vitals Offline Storage ---
  static Future<int> insertVital(VitalSign vital) async {
    final db = await database;
    return await db.insert('vitals', vital.toMap());
  }

  static Future<List<VitalSign>> getVitalsForPatient(int docNo) async {
    final db = await database;
    final maps = await db.query('vitals', where: 'docNo = ?', whereArgs: [docNo], orderBy: 'id DESC');
    return maps.map((m) => VitalSign.fromJson(m)).toList();
  }

  static Future<List<VitalSign>> getUnsyncedVitals() async {
    final db = await database;
    final maps = await db.query('vitals', where: 'isSynced = 0');
    return maps.map((m) => VitalSign.fromJson(m)).toList();
  }

  static Future<void> markVitalSynced(int id) async {
    final db = await database;
    await db.update('vitals', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // --- Intake & Output Storage ---
  static Future<int> insertIntakeOutput(IntakeOutputRecord record) async {
    final db = await database;
    return await db.insert('intake_output', record.toMap());
  }

  static Future<List<IntakeOutputRecord>> getIOForPatient(int docNo) async {
    final db = await database;
    final maps = await db.query('intake_output', where: 'docNo = ?', whereArgs: [docNo], orderBy: 'id DESC');
    return maps.map((m) => IntakeOutputRecord.fromJson(m)).toList();
  }

  static Future<List<IntakeOutputRecord>> getUnsyncedIO() async {
    final db = await database;
    final maps = await db.query('intake_output', where: 'isSynced = 0');
    return maps.map((m) => IntakeOutputRecord.fromJson(m)).toList();
  }

  static Future<void> markIOSynced(int id) async {
    final db = await database;
    await db.update('intake_output', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // --- Doctor Orders Storage ---
  static Future<void> saveDoctorOrders(List<DoctorOrder> orders) async {
    final db = await database;
    for (var order in orders) {
      await db.insert('doctor_orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<List<DoctorOrder>> getDoctorOrdersForPatient(int docNo) async {
    final db = await database;
    final maps = await db.query('doctor_orders', where: 'docNo = ?', whereArgs: [docNo]);
    return maps.map((m) => DoctorOrder.fromJson(m)).toList();
  }

  static Future<List<DoctorOrder>> getUnsyncedDoctorOrders() async {
    final db = await database;
    final maps = await db.query('doctor_orders', where: 'isSynced = 0');
    return maps.map((m) => DoctorOrder.fromJson(m)).toList();
  }

  static Future<void> updateDoctorOrderExecution(int orderId, String notes) async {
    final db = await database;
    await db.update(
      'doctor_orders',
      {
        'isExecuted': 1,
        'executedAt': DateTime.now().toIso8601String(),
        'executionNotes': notes,
        'isSynced': 0
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  static Future<void> markDoctorOrderSynced(int orderId) async {
    final db = await database;
    await db.update('doctor_orders', {'isSynced': 1}, where: 'id = ?', whereArgs: [orderId]);
  }

  // --- Counts ---
  static Future<int> getPendingSyncCount() async {
    final db = await database;
    final vCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM vitals WHERE isSynced = 0')) ?? 0;
    final ioCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM intake_output WHERE isSynced = 0')) ?? 0;
    final doCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM doctor_orders WHERE isSynced = 0')) ?? 0;
    return vCount + ioCount + doCount;
  }

  static Future<void> clearLocalCache() async {
    final db = await database;
    await db.delete('patients');
    await db.delete('vitals');
    await db.delete('intake_output');
    await db.delete('doctor_orders');
  }
}
