import 'question_model.dart';

/// Modelo de respuesta a una pregunta en una cita
class AppointmentAnswerModel {
  final int? answerId;
  final int appointmentId;
  final int questionId;
  final double? numericValue;
  final QuestionModel? question;

  AppointmentAnswerModel({
    this.answerId,
    required this.appointmentId,
    required this.questionId,
    this.numericValue,
    this.question,
  });

  factory AppointmentAnswerModel.fromJson(Map<String, dynamic> json) {
    return AppointmentAnswerModel(
      answerId: json['answerId'] as int?,
      appointmentId: json['appointmentId'] as int,
      questionId: json['questionId'] as int,
      numericValue: json['numericValue'] != null 
          ? double.tryParse(json['numericValue'].toString())
          : null,
      question: json['question'] != null 
          ? QuestionModel.fromJson(json['question'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (answerId != null) 'answerId': answerId,
      'appointmentId': appointmentId,
      'questionId': questionId,
      if (numericValue != null) 'numericValue': numericValue,
    };
  }

  /// Crear copia con nuevos valores
  AppointmentAnswerModel copyWith({
    int? answerId,
    int? appointmentId,
    int? questionId,
    double? numericValue,
    QuestionModel? question,
  }) {
    return AppointmentAnswerModel(
      answerId: answerId ?? this.answerId,
      appointmentId: appointmentId ?? this.appointmentId,
      questionId: questionId ?? this.questionId,
      numericValue: numericValue ?? this.numericValue,
      question: question ?? this.question,
    );
  }

  @override
  String toString() => 
      'AppointmentAnswerModel(id: $answerId, questionId: $questionId, value: $numericValue)';
}

