class PatientModel {
  final int patientId;
  final String fullName;
  final String birthDate;
  final DateTime createdAt;

  PatientModel({
    required this.patientId,
    required this.fullName,
    required this.birthDate,
    required this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patientId'] as int,
      fullName: json['fullName'] as String,
      birthDate: json['birthDate'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'fullName': fullName,
      'birthDate': birthDate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Calcular edad
  int get age {
    final birth = DateTime.parse(birthDate);
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age;
  }
}
