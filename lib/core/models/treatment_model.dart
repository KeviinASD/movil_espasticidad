class TreatmentModel {
  final int treatmentId;
  final String treatmentName;

  TreatmentModel({
    required this.treatmentId,
    required this.treatmentName,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      treatmentId: json['treatmentId'] as int,
      treatmentName: json['treatmentName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'treatmentId': treatmentId,
      'treatmentName': treatmentName,
    };
  }
}
