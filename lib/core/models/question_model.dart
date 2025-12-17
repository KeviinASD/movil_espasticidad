/// Modelo de pregunta cuantitativa para evaluación clínica
class QuestionModel {
  final int questionId;
  final String questionText;

  QuestionModel({
    required this.questionId,
    required this.questionText,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      questionId: json['questionId'] as int,
      questionText: json['questionText'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
    };
  }

  /// Obtener el ícono según el tipo de pregunta
  String get iconName {
    final text = questionText.toLowerCase();
    if (text.contains('espasmo')) return 'waves';
    if (text.contains('ritmo') || text.contains('cardíaco') || text.contains('cardiaco')) return 'favorite';
    if (text.contains('peso')) return 'monitor_weight';
    return 'help_outline';
  }

  /// Obtener la unidad de medida según el tipo de pregunta
  String get unit {
    final text = questionText.toLowerCase();
    if (text.contains('espasmo')) return '/día';
    if (text.contains('bpm') || text.contains('ritmo') || text.contains('cardíaco')) return 'bpm';
    if (text.contains('kg') || text.contains('peso')) return 'kg';
    return '';
  }

  /// Obtener el hint del input según el tipo
  String get inputHint {
    final text = questionText.toLowerCase();
    if (text.contains('espasmo')) return '0';
    if (text.contains('ritmo') || text.contains('cardíaco')) return '60-100';
    if (text.contains('peso')) return '0.0';
    return '0';
  }

  @override
  String toString() => 'QuestionModel(id: $questionId, text: $questionText)';
}

