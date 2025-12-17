/// Estados de cita según el backend
enum AppointmentStatus {
  scheduled('SCHEDULED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  noShow('NO_SHOW');

  final String value;
  const AppointmentStatus(this.value);

  static AppointmentStatus fromString(String status) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => AppointmentStatus.scheduled,
    );
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Programada';
      case AppointmentStatus.inProgress:
        return 'En Proceso';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      case AppointmentStatus.noShow:
        return 'No asistió';
    }
  }
}

class AppointmentModel {
  final int appointmentId;
  final int patientTreatmentId;
  final DateTime appointmentDate;
  final AppointmentStatus status;
  final int? progressPercentage;
  final String? notes;

  AppointmentModel({
    required this.appointmentId,
    required this.patientTreatmentId,
    required this.appointmentDate,
    required this.status,
    this.progressPercentage,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointmentId'] as int,
      patientTreatmentId: json['patientTreatmentId'] as int,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      status: AppointmentStatus.fromString(json['status'] as String),
      progressPercentage: json['progressPercentage'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'patientTreatmentId': patientTreatmentId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'status': status.value,
      'progressPercentage': progressPercentage,
      'notes': notes,
    };
  }

  /// Obtener el ícono representativo según el estado
  String get iconName {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'event';
      case AppointmentStatus.inProgress:
        return 'accessibility_new';
      case AppointmentStatus.completed:
        return 'check_circle';
      case AppointmentStatus.cancelled:
        return 'cancel';
      case AppointmentStatus.noShow:
        return 'event_busy';
    }
  }

  @override
  String toString() =>
      'AppointmentModel(id: $appointmentId, status: ${status.displayName}, date: $appointmentDate)';
}

