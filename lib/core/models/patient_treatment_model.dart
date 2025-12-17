import 'patient_model.dart';
import 'user_model.dart';
import 'treatment_model.dart';

class PatientTreatmentModel {
  final int patientTreatmentId;
  final int patientId;
  final int doctorId;
  final int treatmentId;
  final String startDate;
  final String endDate;
  final PatientModel? patient;
  final UserModel? doctor;
  final TreatmentModel? treatment;

  PatientTreatmentModel({
    required this.patientTreatmentId,
    required this.patientId,
    required this.doctorId,
    required this.treatmentId,
    required this.startDate,
    required this.endDate,
    this.patient,
    this.doctor,
    this.treatment,
  });

  factory PatientTreatmentModel.fromJson(Map<String, dynamic> json) {
    return PatientTreatmentModel(
      patientTreatmentId: json['patientTreatmentId'] as int,
      patientId: json['patientId'] as int,
      doctorId: json['doctorId'] as int,
      treatmentId: json['treatmentId'] as int,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      patient: json['patient'] != null
          ? PatientModel.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      doctor: json['doctor'] != null
          ? UserModel.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
      treatment: json['treatment'] != null
          ? TreatmentModel.fromJson(json['treatment'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientTreatmentId': patientTreatmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'treatmentId': treatmentId,
      'startDate': startDate,
      'endDate': endDate,
      if (patient != null) 'patient': patient!.toJson(),
      if (doctor != null) 'doctor': doctor!.toJson(),
      if (treatment != null) 'treatment': treatment!.toJson(),
    };
  }

  /// Nombre del tratamiento (para mostrar en UI)
  String get treatmentName => treatment?.treatmentName ?? 'Tratamiento #$treatmentId';

  /// Nombre del doctor (para mostrar en UI)
  String get doctorName => doctor?.fullName ?? doctor?.username ?? 'Doctor #$doctorId';

  /// Nombre del paciente (para mostrar en UI)
  String get patientName => patient?.fullName ?? 'Paciente #$patientId';
}
