/// Modelo de herramienta de IA
class AiToolModel {
  final int aiToolId;
  final String name;

  AiToolModel({
    required this.aiToolId,
    required this.name,
  });

  factory AiToolModel.fromJson(Map<String, dynamic> json) {
    return AiToolModel(
      aiToolId: json['aiToolId'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aiToolId': aiToolId,
      'name': name,
    };
  }

  /// Obtener descripción corta del modelo
  String get shortName {
    if (name.toLowerCase().contains('gpt')) return 'ChatGPT-4';
    if (name.toLowerCase().contains('copilot')) return 'Copilot';
    return name;
  }

  @override
  String toString() => 'AiToolModel(id: $aiToolId, name: $name)';
}

