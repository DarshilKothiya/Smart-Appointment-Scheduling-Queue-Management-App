import 'enums.dart';

class Appointment {
  final String id;
  final String appointmentId; // Human-readable ID like APT-001
  final String name;
  final ServiceType serviceType;
  final DateTime date;
  final String timeSlot; // e.g., "09:00 AM"
  AppointmentStatus status;
  int queuePosition;
  int estimatedWaitMinutes;
  final DateTime createdAt;
  bool isSynced;

  Appointment({
    required this.id,
    required this.appointmentId,
    required this.name,
    required this.serviceType,
    required this.date,
    required this.timeSlot,
    this.status = AppointmentStatus.scheduled,
    this.queuePosition = 0,
    this.estimatedWaitMinutes = 0,
    DateTime? createdAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'name': name,
      'serviceType': serviceType.value,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status.value,
      'queuePosition': queuePosition,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      appointmentId: map['appointmentId'],
      name: map['name'],
      serviceType: ServiceType.fromString(map['serviceType']),
      date: DateTime.parse(map['date']),
      timeSlot: map['timeSlot'],
      status: AppointmentStatus.fromString(map['status']),
      queuePosition: map['queuePosition'] ?? 0,
      estimatedWaitMinutes: map['estimatedWaitMinutes'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: (map['isSynced'] ?? 0) == 1,
    );
  }

  Appointment copyWith({
    String? id,
    String? appointmentId,
    String? name,
    ServiceType? serviceType,
    DateTime? date,
    String? timeSlot,
    AppointmentStatus? status,
    int? queuePosition,
    int? estimatedWaitMinutes,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Appointment(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'Appointment(id: $id, name: $name, status: ${status.displayName})';
  }
}
