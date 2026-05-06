import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/appointment.dart';
import '../models/enums.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  static const String _tableName = 'appointments';
  static const String _counterTable = 'counters';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_appointment.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        appointmentId TEXT NOT NULL,
        name TEXT NOT NULL,
        serviceType TEXT NOT NULL,
        date TEXT NOT NULL,
        timeSlot TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'scheduled',
        queuePosition INTEGER NOT NULL DEFAULT 0,
        estimatedWaitMinutes INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $_counterTable (
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Initialize appointment counter
    await db.insert(_counterTable, {'key': 'appointment_count', 'value': 0});
  }

  // Get next appointment number for human-readable ID
  Future<int> _getNextAppointmentNumber() async {
    final db = await database;
    final result = await db.query(
      _counterTable,
      where: 'key = ?',
      whereArgs: ['appointment_count'],
    );

    int current = 0;
    if (result.isNotEmpty) {
      current = result.first['value'] as int;
    }

    final next = current + 1;
    await db.update(
      _counterTable,
      {'value': next},
      where: 'key = ?',
      whereArgs: ['appointment_count'],
    );

    return next;
  }

  Future<String> generateAppointmentId() async {
    final num = await _getNextAppointmentNumber();
    return 'APT-${num.toString().padLeft(4, '0')}';
  }

  // INSERT
  Future<void> insertAppointment(Appointment appointment) async {
    final db = await database;
    await db.insert(
      _tableName,
      appointment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET ALL
  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'queuePosition ASC, createdAt ASC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  // GET BY ID
  Future<Appointment?> getAppointmentById(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Appointment.fromMap(maps.first);
  }

  // GET BY APPOINTMENT ID (human-readable)
  Future<Appointment?> getByAppointmentId(String appointmentId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'appointmentId = ?',
      whereArgs: [appointmentId],
    );
    if (maps.isEmpty) return null;
    return Appointment.fromMap(maps.first);
  }

  // UPDATE
  Future<void> updateAppointment(Appointment appointment) async {
    final db = await database;
    await db.update(
      _tableName,
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  // DELETE
  Future<void> deleteAppointment(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CHECK SLOT AVAILABILITY
  Future<bool> isSlotAvailable(
      DateTime date, String timeSlot, {String? excludeId, int maxPerSlot = 1}) async {
    final db = await database;

    String whereClause =
        "date LIKE ? AND timeSlot = ? AND status != 'cancelled'";
    List<dynamic> whereArgs = ['${date.toIso8601String().substring(0, 10)}%', timeSlot];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );

    return maps.length < maxPerSlot;
  }

  // GET APPOINTMENTS BY DATE
  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      _tableName,
      where: "date LIKE ? AND status != 'cancelled'",
      whereArgs: ['$dateStr%'],
      orderBy: 'queuePosition ASC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  // GET QUEUE (active appointments only)
  Future<List<Appointment>> getActiveQueue() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: "status IN ('scheduled', 'in_progress')",
      orderBy: 'queuePosition ASC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  // GET CURRENT IN-PROGRESS
  Future<Appointment?> getCurrentInProgress() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: "status = 'in_progress'",
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Appointment.fromMap(maps.first);
  }

  // GET UNSYNCED
  Future<List<Appointment>> getUnsyncedAppointments() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'isSynced = 0',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  // MARK AS SYNCED
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SEARCH
  Future<List<Appointment>> searchAppointments(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'name LIKE ? OR appointmentId LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  // FILTER
  Future<List<Appointment>> filterAppointments({
    DateTime? date,
    AppointmentStatus? status,
    ServiceType? serviceType,
  }) async {
    final db = await database;
    List<String> conditions = [];
    List<dynamic> args = [];

    if (date != null) {
      conditions.add("date LIKE ?");
      args.add('${date.toIso8601String().substring(0, 10)}%');
    }
    if (status != null) {
      conditions.add("status = ?");
      args.add(status.value);
    }
    if (serviceType != null) {
      conditions.add("serviceType = ?");
      args.add(serviceType.value);
    }

    final whereClause = conditions.isEmpty ? null : conditions.join(' AND ');

    final maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  // REORDER QUEUE (after cancel/complete)
  Future<void> reorderQueue() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: "status = 'scheduled'",
      orderBy: 'queuePosition ASC, createdAt ASC',
    );

    for (int i = 0; i < maps.length; i++) {
      final id = maps[i]['id'] as String;
      await db.update(
        _tableName,
        {
          'queuePosition': i + 1,
          'estimatedWaitMinutes': (i) * 15,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
