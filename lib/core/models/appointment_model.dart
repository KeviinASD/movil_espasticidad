import 'patient_treatment_model.dart';

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
  final PatientTreatmentModel? patientTreatment;

  AppointmentModel({
    required this.appointmentId,
    required this.patientTreatmentId,
    required this.appointmentDate,
    required this.status,
    this.progressPercentage,
    this.notes,
    this.patientTreatment,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointmentId'] as int,
      patientTreatmentId: json['patientTreatmentId'] as int,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      status: AppointmentStatus.fromString(json['status'] as String),
      progressPercentage: json['progressPercentage'] as int?,
      notes: json['notes'] as String?,
      patientTreatment: json['patientTreatment'] != null
          ? PatientTreatmentModel.fromJson(json['patientTreatment'] as Map<String, dynamic>)
          : null,
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
      'patientTreatment': patientTreatment?.toJson(),
    };
  }

  // Helper para obtener el nombre del paciente
  String get patientName =>
      patientTreatment?.patient?.fullName ?? 'Sin paciente';

  // Helper para obtener el nombre del tratamiento
  String get treatmentName =>
      patientTreatment?.treatment?.treatmentName ?? 'Sin tratamiento';

  // Helper para verificar si es hoy
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
        appointmentDate.month == now.month &&
        appointmentDate.day == now.day;
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

