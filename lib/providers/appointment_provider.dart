import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String _searchQuery = '';
  AppointmentStatus? _statusFilter;
  ServiceType? _serviceFilter;
  DateTime? _dateFilter;
  String? _errorMessage;
  StreamSubscription? _connectivitySub;

  // Getters
  List<Appointment> get appointments => _filteredAppointments;
  List<Appointment> get allAppointments => _appointments;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  AppointmentStatus? get statusFilter => _statusFilter;
  ServiceType? get serviceFilter => _serviceFilter;
  DateTime? get dateFilter => _dateFilter;

  // Queue getters
  List<Appointment> get activeQueue => _appointments
      .where((a) =>
          a.status == AppointmentStatus.scheduled ||
          a.status == AppointmentStatus.inProgress)
      .toList()
    ..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));

  Appointment? get currentServing => _appointments
      .where((a) => a.status == AppointmentStatus.inProgress)
      .firstOrNull;

  int get totalScheduled =>
      _appointments.where((a) => a.status == AppointmentStatus.scheduled).length;

  int get totalCompleted =>
      _appointments.where((a) => a.status == AppointmentStatus.completed).length;

  int get totalCancelled =>
      _appointments.where((a) => a.status == AppointmentStatus.cancelled).length;

  Future<void> initialize() async {
    await _connectivity.initialize();
    _isConnected = _connectivity.isConnected;

    _connectivitySub = _connectivity.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    await loadAppointments();
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _appointments = await _db.getAllAppointments();
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load appointments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── BOOKING ───────────────────────────────────────────────────────────────

  Future<({bool success, String message, Appointment? appointment})>
      bookAppointment({
    required String name,
    required ServiceType serviceType,
    required DateTime date,
    required String timeSlot,
  }) async {
    // Validation
    if (name.trim().isEmpty) {
      return (success: false, message: 'Please enter your name', appointment: null);
    }

    final now = DateTime.now();
    final appointmentDateTime = _parseDateTime(date, timeSlot);

    if (appointmentDateTime.isBefore(now)) {
      return (
        success: false,
        message: 'Cannot book a past date/time',
        appointment: null
      );
    }

    // Conflict check
    final slotAvailable = await _db.isSlotAvailable(date, timeSlot);
    if (!slotAvailable) {
      return (
        success: false,
        message: 'This time slot is already booked. Please choose another.',
        appointment: null
      );
    }

    try {
      final id = const Uuid().v4();
      final appointmentId = await _db.generateAppointmentId();
      final queuePosition = activeQueue.length + 1;

      final appointment = Appointment(
        id: id,
        appointmentId: appointmentId,
        name: name.trim(),
        serviceType: serviceType,
        date: date,
        timeSlot: timeSlot,
        status: AppointmentStatus.scheduled,
        queuePosition: queuePosition,
        estimatedWaitMinutes: (queuePosition - 1) * 15,
        isSynced: false,
      );

      await _db.insertAppointment(appointment);
      await loadAppointments();

      return (
        success: true,
        message: 'Appointment booked successfully!\nID: $appointmentId',
        appointment: appointment
      );
    } catch (e) {
      return (success: false, message: 'Booking failed: $e', appointment: null);
    }
  }

  // ─── ADMIN CONTROLS ────────────────────────────────────────────────────────

  Future<void> markAsInProgress(String id) async {
    try {
      // Mark any in-progress as completed first
      final current = currentServing;
      if (current != null) {
        current.status = AppointmentStatus.completed;
        await _db.updateAppointment(current);
      }

      final appointment = await _db.getAppointmentById(id);
      if (appointment != null) {
        appointment.status = AppointmentStatus.inProgress;
        await _db.updateAppointment(appointment);
        await _db.reorderQueue();
        await loadAppointments();
      }
    } catch (e) {
      _errorMessage = 'Failed to update status: $e';
      notifyListeners();
    }
  }

  Future<void> markAsCompleted(String id) async {
    try {
      final appointment = await _db.getAppointmentById(id);
      if (appointment != null) {
        appointment.status = AppointmentStatus.completed;
        await _db.updateAppointment(appointment);
        await _db.reorderQueue();
        await loadAppointments();
      }
    } catch (e) {
      _errorMessage = 'Failed to complete appointment: $e';
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String id) async {
    try {
      final appointment = await _db.getAppointmentById(id);
      if (appointment != null) {
        appointment.status = AppointmentStatus.cancelled;
        await _db.updateAppointment(appointment);
        await _db.reorderQueue();
        await loadAppointments();
      }
    } catch (e) {
      _errorMessage = 'Failed to cancel appointment: $e';
      notifyListeners();
    }
  }

  Future<({bool success, String message})> rescheduleAppointment({
    required String id,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    final now = DateTime.now();
    final newDateTime = _parseDateTime(newDate, newTimeSlot);

    if (newDateTime.isBefore(now)) {
      return (success: false, message: 'Cannot reschedule to a past date/time');
    }

    final slotAvailable =
        await _db.isSlotAvailable(newDate, newTimeSlot, excludeId: id);
    if (!slotAvailable) {
      return (
        success: false,
        message: 'This time slot is already booked. Please choose another.'
      );
    }

    try {
      final appointment = await _db.getAppointmentById(id);
      if (appointment != null) {
        final updated = appointment.copyWith(
          date: newDate,
          timeSlot: newTimeSlot,
          status: AppointmentStatus.scheduled,
          isSynced: false,
        );
        await _db.updateAppointment(updated);
        await _db.reorderQueue();
        await loadAppointments();
        return (success: true, message: 'Appointment rescheduled successfully');
      }
      return (success: false, message: 'Appointment not found');
    } catch (e) {
      return (success: false, message: 'Reschedule failed: $e');
    }
  }

  // Advance queue to next appointment
  Future<void> advanceQueue() async {
    try {
      final queue = activeQueue;
      if (queue.isEmpty) return;

      // Complete in-progress
      final inProgress =
          queue.where((a) => a.status == AppointmentStatus.inProgress).toList();
      for (final a in inProgress) {
        a.status = AppointmentStatus.completed;
        await _db.updateAppointment(a);
      }

      // Move first scheduled to in-progress
      final nextScheduled =
          queue.where((a) => a.status == AppointmentStatus.scheduled).firstOrNull;
      if (nextScheduled != null) {
        nextScheduled.status = AppointmentStatus.inProgress;
        await _db.updateAppointment(nextScheduled);
      }

      await _db.reorderQueue();
      await loadAppointments();
    } catch (e) {
      _errorMessage = 'Failed to advance queue: $e';
      notifyListeners();
    }
  }

  // ─── SEARCH & FILTER ──────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(AppointmentStatus? status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setServiceFilter(ServiceType? service) {
    _serviceFilter = service;
    _applyFilters();
  }

  void setDateFilter(DateTime? date) {
    _dateFilter = date;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _serviceFilter = null;
    _dateFilter = null;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Appointment>.from(_appointments);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.appointmentId.toLowerCase().contains(q))
          .toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((a) => a.status == _statusFilter).toList();
    }

    if (_serviceFilter != null) {
      filtered =
          filtered.where((a) => a.serviceType == _serviceFilter).toList();
    }

    if (_dateFilter != null) {
      filtered = filtered.where((a) {
        return a.date.year == _dateFilter!.year &&
            a.date.month == _dateFilter!.month &&
            a.date.day == _dateFilter!.day;
      }).toList();
    }

    _filteredAppointments = filtered;
    notifyListeners();
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  DateTime _parseDateTime(DateTime date, String timeSlot) {
    // timeSlot like "09:00 AM"
    try {
      final parts = timeSlot.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1] == 'PM' && hour != 12) hour += 12;
      if (parts.length > 1 && parts[1] == 'AM' && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return date;
    }
  }

  int getUserQueuePosition(String appointmentId) {
    final queue = activeQueue;
    final idx = queue.indexWhere((a) => a.id == appointmentId);
    return idx == -1 ? 0 : idx + 1;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _connectivity.dispose();
    super.dispose();
  }
}
