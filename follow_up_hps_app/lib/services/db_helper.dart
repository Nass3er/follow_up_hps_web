import 'dart:convert';
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
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE patients (
          patientNo TEXT PRIMARY KEY,
          patientName TEXT,
          age TEXT,
          ageType INTEGER,
          gender INTEGER,
          roomNo INTEGER,
          bedNo INTEGER,
          roomService INTEGER,
          buldNo INTEGER,
          deptNo INTEGER,
          dctrNo TEXT,
          doctorName TEXT,
          admDate TEXT,
          docNo TEXT,
          docSrl INTEGER,
          cacheKey TEXT
        )''');

      await db.execute('''
        CREATE TABLE vitals (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          docSrl INTEGER,
          docNo TEXT,
          docSrlAdmt INTEGER,
          patientNo TEXT,
          age TEXT,
          ageType INTEGER,
          roomNo INTEGER,
          bedNo INTEGER,
          roomSer INTEGER,
          buildingNo INTEGER,
          docTime TEXT,
          nurseEmpNo INTEGER,
          temperature REAL,
          pulseRate REAL,
          respirationRate REAL,
          spO2 REAL,
          bloodPressureOne REAL,
          bloodPressureTwo REAL,
          notes TEXT,
          isSynced INTEGER DEFAULT 0
        )''');

      await db.execute('''
        CREATE TABLE io_records (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          docSrl INTEGER,
          docNo TEXT,
          docSrlAdmt INTEGER,
          patientNo TEXT,
          age TEXT,
          ageType INTEGER,
          roomNo INTEGER,
          bedNo INTEGER,
          roomSer INTEGER,
          buildingNo INTEGER,
          docTime TEXT,
          nurseEmpNo INTEGER,
          inIvf REAL DEFAULT 0,
          inOral REAL DEFAULT 0,
          inNgt REAL DEFAULT 0,
          inBld REAL DEFAULT 0,
          inOthr REAL DEFAULT 0,
          outUrine REAL DEFAULT 0,
          outGstrc REAL DEFAULT 0,
          outDrng1 REAL DEFAULT 0,
          outDrng2 REAL DEFAULT 0,
          outEmss REAL DEFAULT 0,
          outOthr REAL DEFAULT 0,
          notes TEXT,
          isSynced INTEGER DEFAULT 0
        )''');

      await db.execute('''
        CREATE TABLE unsynced_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recordType TEXT,
          apiUrl TEXT,
          httpMethod TEXT,
          dto TEXT,
          recordId INTEGER,
          timestamp INTEGER
        )''');
    });
  }

  static Future<void> savePatient(Patient patient) async {
    final db = await database;
    await db.insert('patients', patient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Patient?> getPatient(dynamic docNo) async {
    final db = await database;
    final maps = await db.query('patients', where: 'docNo = ?', whereArgs: [docNo.toString()]);
    if (maps.isNotEmpty) return Patient.fromJson(maps.first);
    return null;
  }

  static Future<List<VitalSign>> getUnsyncedVitals() async {
    final db = await database;
    final maps = await db.query('vitals', where: 'isSynced = 0');
    return maps.map((m) => VitalSign.fromJson(m)).toList();
  }

  static Future<void> insertVital(VitalSign vital) async {
    final db = await database;
    await db.insert('vitals', vital.toMap());
  }

  static Future<void> markVitalSynced(int localId) async {
    final db = await database;
    await db.update('vitals', {'isSynced': 1}, where: 'localId = ?', whereArgs: [localId]);
  }

  static Future<List<IntakeOutputRecord>> getUnsyncedIO() async {
    final db = await database;
    final maps = await db.query('io_records', where: 'isSynced = 0');
    return maps.map((m) => IntakeOutputRecord.fromJson(m)).toList();
  }

  static Future<void> insertIO(IntakeOutputRecord record) async {
    final db = await database;
    await db.insert('io_records', record.toMap());
  }

  static Future<void> markIOSynced(int localId) async {
    final db = await database;
    await db.update('io_records', {'isSynced': 1}, where: 'localId = ?', whereArgs: [localId]);
  }

  static Future<int> insertUnsyncedRecord(String type, String url, String method, Map<String, dynamic> dto, int? recordId) async {
    final db = await database;
    return await db.insert('unsynced_records', {
      'recordType': type,
      'apiUrl': url,
      'httpMethod': method,
      'dto': jsonEncode(dto),
      'recordId': recordId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final db = await database;
    return await db.query('unsynced_records', orderBy: 'timestamp ASC');
  }

  static Future<void> deleteUnsyncedRecord(int id) async {
    final db = await database;
    await db.delete('unsynced_records', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> getPendingSyncCount() async {
    final db = await database;
    final v = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM vitals WHERE isSynced = 0')) ?? 0;
    final io = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM io_records WHERE isSynced = 0')) ?? 0;
    final u = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM unsynced_records')) ?? 0;
    return v + io + u;
  }

  static Future<void> clearLocalCache() async {
    final db = await database;
    await db.delete('patients');
    await db.delete('vitals', where: 'isSynced = 1');
    await db.delete('io_records', where: 'isSynced = 1');
  }
}
