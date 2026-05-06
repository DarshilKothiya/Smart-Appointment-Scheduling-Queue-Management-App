import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/appointment.dart';
import '../models/enums.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  static const String _appointmentsStore = 'appointments';
  static const String _countersStore = 'counters';

  // Sembast stores
  final _appointments = stringMapStoreFactory.store(_appointmentsStore);
  final _counters = stringMapStoreFactory.store(_countersStore);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Web: sembast uses IndexedDB, no config needed
      return await databaseFactoryWeb.openDatabase('smart_appointment.db');
    } else {
      // Mobile / Desktop: sembast uses a plain file
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, 'smart_appointment.db');
      return await databaseFactoryIo.openDatabase(dbPath);
    }
  }

  // ─── Counter helpers ────────────────────────────────────────────────────────

  Future<int> _getNextAppointmentNumber() async {
    final db = await database;
    return db.transaction((txn) async {
      final record = _counters.record('appointment_count');
      final existing = await record.get(txn);
      final current = (existing?['value'] as int?) ?? 0;
      final next = current + 1;
      await record.put(txn, {'value': next});
      return next;
    });
  }

  Future<String> generateAppointmentId() async {
    final num = await _getNextAppointmentNumber();
    return 'APT-${num.toString().padLeft(4, '0')}';
  }

  // ─── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> insertAppointment(Appointment appointment) async {
    final db = await database;
    await _appointments.record(appointment.id).put(db, _toSembastMap(appointment));
  }

  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    final snapshots = await _appointments.find(
      db,
      finder: Finder(sortOrders: [
        SortOrder('queuePosition'),
        SortOrder('createdAt'),
      ]),
    );
    return snapshots.map((s) => _fromSembastMap(s.value)).toList();
  }

  Future<Appointment?> getAppointmentById(String id) async {
    final db = await database;
    final snapshot = await _appointments.record(id).get(db);
    if (snapshot == null) return null;
    return _fromSembastMap(snapshot);
  }

  Future<Appointment?> getByAppointmentId(String appointmentId) async {
    final db = await database;
    final snapshots = await _appointments.find(
      db,
      finder: Finder(filter: Filter.equals('appointmentId', appointmentId)),
    );
    if (snapshots.isEmpty) return null;
    return _fromSembastMap(snapshots.first.value);
  }

  Future<void> updateAppointment(Appointment appointment) async {
    final db = await database;
    await _appointments.record(appointment.id).put(db, _toSembastMap(appointment));
  }

  Future<void> deleteAppointment(String id) async {
    final db = await database;
    await _appointments.record(id).delete(db);
  }

  // ─── Slot availability ──────────────────────────────────────────────────────

  Future<bool> isSlotAvailable(
    DateTime date,
    String timeSlot, {
    String? excludeId,
    int maxPerSlot = 1,
  }) async {
    final db = await database;
    final datePrefix = date.toIso8601String().substring(0, 10);

    final snapshots = await _appointments.find(db);
    final matching = snapshots.where((s) {
      final m = s.value;
      if ((m['date'] as String).startsWith(datePrefix) == false) return false;
      if (m['timeSlot'] != timeSlot) return false;
      if (m['status'] == 'cancelled') return false;
      if (excludeId != null && m['id'] == excludeId) return false;
      return true;
    }).toList();

    return matching.length < maxPerSlot;
  }

  // ─── Queries ─────────────────────────────────────────────────────────────────

  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    final db = await database;
    final datePrefix = date.toIso8601String().substring(0, 10);
    final snapshots = await _appointments.find(
      db,
      finder: Finder(
        filter: Filter.and([
          Filter.custom((r) => (r['date'] as String).startsWith(datePrefix)),
          Filter.not(Filter.equals('status', 'cancelled')),
        ]),
        sortOrders: [SortOrder('queuePosition')],
      ),
    );
    return snapshots.map((s) => _fromSembastMap(s.value)).toList();
  }

  Future<List<Appointment>> getActiveQueue() async {
    final db = await database;
    final snapshots = await _appointments.find(
      db,
      finder: Finder(
        filter: Filter.or([
          Filter.equals('status', 'scheduled'),
          Filter.equals('status', 'in_progress'),
        ]),
        sortOrders: [SortOrder('queuePosition')],
      ),
    );
    return snapshots.map((s) => _fromSembastMap(s.value)).toList();
  }

  Future<Appointment?> getCurrentInProgress() async {
    final db = await database;
    final snapshots = await _appointments.find(
      db,
      finder: Finder(
        filter: Filter.equals('status', 'in_progress'),
        limit: 1,
      ),
    );
    if (snapshots.isEmpty) return null;
    return _fromSembastMap(snapshots.first.value);
  }

  Future<List<Appointment>> getUnsyncedAppointments() async {
    final db = await database;
    final snapshots = await _appointments.find(
      db,
      finder: Finder(filter: Filter.equals('isSynced', 0)),
    );
    return snapshots.map((s) => _fromSembastMap(s.value)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await _appointments.record(id).update(db, {'isSynced': 1});
  }

  Future<List<Appointment>> searchAppointments(String query) async {
    final db = await database;
    final lower = query.toLowerCase();
    final snapshots = await _appointments.find(
      db,
      finder: Finder(
        filter: Filter.custom((r) {
          final name = (r['name'] as String? ?? '').toLowerCase();
          final apptId = (r['appointmentId'] as String? ?? '').toLowerCase();
          return name.contains(lower) || apptId.contains(lower);
        }),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return snapshots.map((s) => _fromSembastMap(s.value)).toList();
  }

  Future<List<Appointment>> filterAppointments({
    DateTime? date,
    AppointmentStatus? status,
    ServiceType? serviceType,
  }) async {
    final db = await database;
    final List<Filter> filters = [];

    if (date != null) {
      final datePrefix = date.toIso8601String().substring(0, 10);
      filters.add(Filter.custom((r) => (r['date'] as String).startsWith(datePrefix)));
    }
    if (status != null) {
      filters.add(Filter.equals('status', status.value));
    }
    if (serviceType != null) {
      filters.add(Filter.equals('serviceType', serviceType.value));
    }

    final finder = Finder(
      filter: filters.isEmpty ? null : Filter.and(filters),
      sortOrders: [SortOrder('createdAt', false)],
    );

    final snapshots = await _appointments.find(db, finder: finder);
    return snapshots.map((s) => _fromSembastMap(s.value)).toList();
  }

  // ─── Queue reordering ───────────────────────────────────────────────────────

  Future<void> reorderQueue() async {
    final db = await database;
    final snapshots = await _appointments.find(
      db,
      finder: Finder(
        filter: Filter.equals('status', 'scheduled'),
        sortOrders: [SortOrder('queuePosition'), SortOrder('createdAt')],
      ),
    );

    await db.transaction((txn) async {
      for (int i = 0; i < snapshots.length; i++) {
        await _appointments.record(snapshots[i].key).update(txn, {
          'queuePosition': i + 1,
          'estimatedWaitMinutes': i * 15,
        });
      }
    });
  }

  Future<void> closeDatabase() async {
    await _database?.close();
    _database = null;
  }

  // ─── Serialization helpers ──────────────────────────────────────────────────

  Map<String, dynamic> _toSembastMap(Appointment a) {
    return {
      'id': a.id,
      'appointmentId': a.appointmentId,
      'name': a.name,
      'serviceType': a.serviceType.value,
      'date': a.date.toIso8601String(),
      'timeSlot': a.timeSlot,
      'status': a.status.value,
      'queuePosition': a.queuePosition,
      'estimatedWaitMinutes': a.estimatedWaitMinutes,
      'createdAt': a.createdAt.toIso8601String(),
      'isSynced': a.isSynced ? 1 : 0,
    };
  }

  Appointment _fromSembastMap(Map<String, dynamic> m) {
    return Appointment(
      id: m['id'] as String,
      appointmentId: m['appointmentId'] as String,
      name: m['name'] as String,
      serviceType: ServiceType.fromString(m['serviceType'] as String),
      date: DateTime.parse(m['date'] as String),
      timeSlot: m['timeSlot'] as String,
      status: AppointmentStatus.fromString(m['status'] as String),
      queuePosition: (m['queuePosition'] as int?) ?? 0,
      estimatedWaitMinutes: (m['estimatedWaitMinutes'] as int?) ?? 0,
      createdAt: DateTime.parse(m['createdAt'] as String),
      isSynced: ((m['isSynced'] as int?) ?? 0) == 1,
    );
  }
}
