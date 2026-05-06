// Appointment Status Enum
enum AppointmentStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'scheduled';
      case AppointmentStatus.inProgress:
        return 'in_progress';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
    }
  }

  static AppointmentStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.scheduled;
    }
  }
}

// Service Types
enum ServiceType {
  generalConsultation,
  dentalCheckup,
  eyeExamination,
  bloodTest,
  xRay,
  vaccination,
  counseling,
  haircut,
  salon,
  collegeOffice,
  other;

  String get displayName {
    switch (this) {
      case ServiceType.generalConsultation:
        return 'General Consultation';
      case ServiceType.dentalCheckup:
        return 'Dental Checkup';
      case ServiceType.eyeExamination:
        return 'Eye Examination';
      case ServiceType.bloodTest:
        return 'Blood Test';
      case ServiceType.xRay:
        return 'X-Ray';
      case ServiceType.vaccination:
        return 'Vaccination';
      case ServiceType.counseling:
        return 'Counseling';
      case ServiceType.haircut:
        return 'Haircut';
      case ServiceType.salon:
        return 'Salon Service';
      case ServiceType.collegeOffice:
        return 'College Office';
      case ServiceType.other:
        return 'Other';
    }
  }

  String get value => name;

  static ServiceType fromString(String value) {
    return ServiceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceType.other,
    );
  }
}
