import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/models/ai_tool_model.dart';
import '../../../core/models/ai_evaluation_model.dart';
import '../../../core/services/ai_tools_service.dart';
import '../../../core/services/ai_evaluations_service.dart';
import '../../../core/services/diagnoses_service.dart';
import '../../../core/services/appointment_answers_service.dart';
import '../../../core/models/appointment_answer_model.dart';
import '../../../core/providers/auth_store.dart';

/// Pantalla de diagnóstico con IA
class AiDiagnosisPage extends StatefulWidget {
  final AppointmentModel appointment;
  final String? patientName;
  final String? patientCondition;

  const AiDiagnosisPage({
    super.key,
    required this.appointment,
    this.patientName,
    this.patientCondition,
  });

  @override
  State<AiDiagnosisPage> createState() => _AiDiagnosisPageState();
}

class _AiDiagnosisPageState extends State<AiDiagnosisPage> {
  final AiToolsService _aiToolsService = AiToolsService();
  final AiEvaluationsService _aiEvaluationsService = AiEvaluationsService();
  final DiagnosesService _diagnosesService = DiagnosesService();
  final AppointmentAnswersService _appointmentAnswersService = AppointmentAnswersService();
  final TextEditingController _justificationController = TextEditingController();

  List<AiToolModel> _aiTools = [];
  List<AiEvaluationModel> _evaluations = [];
  List<AppointmentAnswerModel> _clinicalAnswers = [];
  int _selectedToolIndex = 0;
  int? _selectedEvaluationId;
  String _selectedJustificationChip = 'Clínica Coincidente';
  
  bool _isLoading = true;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      // Cargar herramientas de IA
      final aiTools = await _aiToolsService.getAll(token: token);

      // Cargar evaluaciones existentes
      final evaluations = await _aiEvaluationsService.getByAppointment(
        widget.appointment.appointmentId,
        token: token,
      );

      // Cargar respuestas de evaluación clínica (datos reales del paciente)
      final answers = await _appointmentAnswersService.getByAppointment(
        widget.appointment.appointmentId,
        token: token,
      );

      // Encontrar evaluación seleccionada
      final selected = evaluations.where((e) => e.isSelected).firstOrNull;

      if (!mounted) return;
      setState(() {
        _aiTools = aiTools;
        _evaluations = evaluations;
        _clinicalAnswers = answers;
        _selectedEvaluationId = selected?.evaluationId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Construye los datos clínicos desde la evaluación clínica guardada
  Map<String, dynamic> _buildClinicalDataFromAnswers() {
    final findings = <String>[];
    String? masValue;

    // Agrupar respuestas por pregunta y tomar la más reciente
    final Map<int, AppointmentAnswerModel> latestAnswers = {};
    for (final answer in _clinicalAnswers) {
      if (answer.numericValue == null) continue;
      
      final questionId = answer.questionId;
      final existingAnswer = latestAnswers[questionId];
      if (existingAnswer == null ||
          (answer.answerId != null &&
              existingAnswer.answerId != null &&
              answer.answerId! > existingAnswer.answerId!)) {
        latestAnswers[questionId] = answer;
      }
    }

    // Mapear respuestas cuantitativas de la evaluación clínica (6 indicadores)
    for (final answer in latestAnswers.values) {
      final question = answer.question;
      if (question == null || answer.numericValue == null) continue;

      final questionText = question.questionText.toLowerCase();
      final value = answer.numericValue!;

      // 1. Modified Ashworth Scale (MAS)
      if (questionText.contains('ashworth') || questionText.contains('mas')) {
        findings.add('Modified Ashworth Scale (MAS): ${value.toString()}');
        masValue = value.toString();
      } 
      // 2. Frecuencia de espasmos musculares
      else if (questionText.contains('espasmo') || questionText.contains('frecuencia')) {
        findings.add('Frecuencia de espasmos musculares: ${value.toInt()} por día');
      } 
      // 3. H-Reflex Ratio
      else if (questionText.contains('h-reflex') || 
               questionText.contains('hmax') || 
               questionText.contains('mmax') ||
               questionText.contains('h max') ||
               questionText.contains('m max')) {
        findings.add('H-Reflex Ratio (Hmax / Mmax): ${value.toStringAsFixed(2)}');
      } 
      // 4. Stretch Reflex Threshold (SRT)
      else if (questionText.contains('stretch') || 
               questionText.contains('srt') || 
               questionText.contains('threshold')) {
        findings.add('Stretch Reflex Threshold (SRT): ${value.toStringAsFixed(1)} °/s');
      }
      // 5. Ritmo cardíaco
      else if (questionText.contains('ritmo') || 
               questionText.contains('cardiaco') || 
               questionText.contains('cardíaco') ||
               questionText.contains('bpm')) {
        findings.add('Ritmo cardíaco: ${value.toInt()} bpm');
      }
      // 6. Peso
      else if (questionText.contains('peso') || questionText.contains('kg')) {
        findings.add('Peso: ${value.toStringAsFixed(1)} kg');
      }
      // Cualquier otro indicador
      else {
        findings.add('${question.questionText}: ${value}');
      }
    }

    // Si hay notas en la cita, agregarlas
    if (widget.appointment.notes != null && widget.appointment.notes!.isNotEmpty) {
      findings.add('Notas adicionales: ${widget.appointment.notes}');
    }

    // Construir texto de hallazgos final
    final findingsText = findings.isNotEmpty
        ? findings.join('. ')
        : 'Evaluación clínica realizada. Datos cuantitativos registrados.';

    return {
      'findings': findingsText,
      'masScale': masValue,
      'medications': null,
      'patientAge': null,
    };
  }

  Future<void> _runAnalysis() async {
    if (_aiTools.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;
      final selectedTool = _aiTools[_selectedToolIndex];

      // Construir datos clínicos combinando entrada manual y datos cuantitativos
      final clinicalData = _buildClinicalDataFromAnswers();

      // Asegurar que findings no esté vacío (requerido por el backend)
      final findings = clinicalData['findings'] as String?;
      if (findings == null || findings.trim().isEmpty || _clinicalAnswers.isEmpty) {
        throw Exception('No hay datos de evaluación clínica disponibles. Por favor, complete la evaluación clínica primero.');
      }

      // Validar que appointmentId y aiToolId sean válidos
      if (widget.appointment.appointmentId <= 0) {
        throw Exception('ID de cita inválido');
      }
      
      if (selectedTool.aiToolId <= 0) {
        throw Exception('ID de herramienta de IA inválido');
      }

      // Llamar al endpoint del backend que usa GPT/Copilot para generar el análisis
      await _aiEvaluationsService.generateWithCopilot(
        appointmentId: widget.appointment.appointmentId,
        aiToolId: selectedTool.aiToolId,
        findings: findings.trim(),
        masScale: clinicalData['masScale'] as String?,
        medications: clinicalData['medications'] as String?,
        patientAge: clinicalData['patientAge'] as int?,
        patientCondition: widget.patientCondition ?? 'Espasticidad post-ictus',
        token: token,
      );

      if (!mounted) return;
      
      // Recargar evaluaciones
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Análisis completado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      
      // Extraer el mensaje de error
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      // Si el error contiene información adicional, intentar extraerla
      if (errorMessage.contains(':')) {
        final parts = errorMessage.split(':');
        if (parts.length > 1) {
          errorMessage = parts.sublist(1).join(':').trim();
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage.isNotEmpty ? errorMessage : 'Error al generar análisis'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _saveEvaluation() async {
    if (_selectedEvaluationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una evaluación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      // Construir justificación
      final justification = _justificationController.text.isEmpty
          ? _selectedJustificationChip
          : '${_selectedJustificationChip}: ${_justificationController.text}';

      // Seleccionar evaluación
      await _aiEvaluationsService.selectEvaluation(
        _selectedEvaluationId!,
        justification: justification,
        token: token,
      );

      // Crear diagnóstico
      await _diagnosesService.create(
        appointmentId: widget.appointment.appointmentId,
        hasSpasticity: true,
        diagnosisSummary: 'Diagnóstico basado en evaluación IA seleccionada',
        token: token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evaluación guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patientName = widget.patientName ?? 'Paciente';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorWidget()
                      : _buildContent(isDark, patientName),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1C1C1E) : Colors.white).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!.withOpacity(0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Botón atrás estilo iOS
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 22,
                    color: const Color(0xFF007AFF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Atrás',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
            ),
            
            // Título centrado
            Expanded(
              child: Text(
                'Diagnóstico IA',
                style: GoogleFonts.notoSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Botón más opciones
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.more_horiz,
                color: const Color(0xFF007AFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, String patientName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del paciente
          _buildPatientInfo(isDark, patientName),
          
          // Datos clínicos expandibles
          _buildClinicalDataAccordion(isDark),
          
          // Selector de modelo IA
          _buildAiModelSelector(isDark),
          
          // Título análisis
          _buildAnalysisHeader(isDark),
          
          // Resultados de IA (solo mostrar si hay evaluaciones para la herramienta seleccionada)
          Builder(
            builder: (context) {
              final selectedTool = _aiTools.isNotEmpty ? _aiTools[_selectedToolIndex] : null;
              final hasEvaluationsForTool = selectedTool != null && 
                  _evaluations.any((e) => e.aiToolId == selectedTool.aiToolId);
              
              if (hasEvaluationsForTool)
                return _buildAiResultCard(isDark);
              else if (_isAnalyzing)
                return _buildAnalyzingCard(isDark);
              else
                return _buildNoResultsCard(isDark);
            },
          ),
          
          // Selección para base de datos (mostrar si hay CUALQUIERA evaluación disponible)
          if (_evaluations.isNotEmpty) ...[
            _buildSelectionSection(isDark),
            _buildJustificationSection(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientInfo(bool isDark, String patientName) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF007AFF).withOpacity(0.15),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(patientName),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF007AFF),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '45 años • ID: #${widget.appointment.appointmentId}',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.accessibility_new,
                        size: 16,
                        color: const Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.patientCondition ?? 'Espasticidad post-ictus',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalDataAccordion(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!.withOpacity(0.5),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.description,
                color: const Color(0xFF007AFF),
                size: 20,
              ),
            ),
            title: Text(
              'Datos Clínicos (Entrada)',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            trailing: Icon(
              Icons.expand_more,
              color: Colors.grey[400],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                    ),
                  ),
                ),
                child: _buildClinicalDataDisplay(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicalDataDisplay(bool isDark) {
    if (_clinicalAnswers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No hay datos de evaluación clínica disponibles. Por favor, complete la evaluación clínica primero.',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    // Agrupar respuestas por questionId para evitar duplicados
    // Si hay múltiples respuestas para la misma pregunta, tomar la más reciente
    final Map<int, AppointmentAnswerModel> uniqueAnswers = {};
    for (final answer in _clinicalAnswers) {
      if (answer.numericValue != null) {
        // Si ya existe una respuesta para esta pregunta, mantener la que tenga el answerId más alto (más reciente)
        if (!uniqueAnswers.containsKey(answer.questionId) || 
            (answer.answerId != null && 
             uniqueAnswers[answer.questionId]?.answerId != null &&
             answer.answerId! > uniqueAnswers[answer.questionId]!.answerId!)) {
          uniqueAnswers[answer.questionId] = answer;
        }
      }
    }

    // Convertir a lista y ordenar por questionId para mantener consistencia
    final uniqueAnswersList = uniqueAnswers.values.toList()
      ..sort((a, b) => a.questionId.compareTo(b.questionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: uniqueAnswersList.map((answer) {
        final question = answer.question;
        if (question == null || answer.numericValue == null) {
          return const SizedBox.shrink();
        }

        final questionText = question.questionText;
        final value = answer.numericValue!;
        String displayValue = '';
        String unit = '';
        String label = questionText;

        // Formatear el valor según el tipo de pregunta (6 indicadores)
        final textLower = questionText.toLowerCase();
        
        // 1. Modified Ashworth Scale (MAS)
        if (textLower.contains('ashworth') || textLower.contains('mas')) {
          displayValue = value.toString();
          unit = '';
          label = 'Modified Ashworth Scale (MAS)';
        } 
        // 2. Frecuencia de espasmos musculares
        else if (textLower.contains('espasmo') || textLower.contains('frecuencia')) {
          displayValue = value.toInt().toString();
          unit = '/día';
          label = 'Frecuencia de espasmos musculares';
        } 
        // 3. H-Reflex Ratio
        else if (textLower.contains('h-reflex') || 
                 textLower.contains('hmax') || 
                 textLower.contains('mmax') ||
                 textLower.contains('h max') ||
                 textLower.contains('m max')) {
          displayValue = value.toStringAsFixed(2);
          unit = '';
          label = 'H-Reflex Ratio (Hmax / Mmax)';
        } 
        // 4. Stretch Reflex Threshold (SRT)
        else if (textLower.contains('stretch') || 
                 textLower.contains('srt') || 
                 textLower.contains('threshold')) {
          displayValue = value.toStringAsFixed(1);
          unit = '°/s';
          label = 'Stretch Reflex Threshold (SRT)';
        }
        // 5. Ritmo cardíaco
        else if (textLower.contains('ritmo') || 
                 textLower.contains('cardiaco') || 
                 textLower.contains('cardíaco') ||
                 textLower.contains('bpm')) {
          displayValue = value.toInt().toString();
          unit = 'bpm';
          label = 'Ritmo cardíaco';
        }
        // 6. Peso
        else if (textLower.contains('peso') || textLower.contains('kg')) {
          displayValue = value.toStringAsFixed(1);
          unit = 'kg';
          label = 'Peso';
        }
        // Cualquier otro indicador
        else {
          displayValue = value.toString();
          unit = '';
        }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• $label: ',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        unit.isNotEmpty ? '$displayValue $unit' : displayValue,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              );
      }).toList(),
    );
  }

  Widget _buildAiModelSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ANÁLISIS INTELIGENTE',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Selector de modelo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: _aiTools.asMap().entries.map((entry) {
                final index = entry.key;
                final tool = entry.value;
                final isSelected = index == _selectedToolIndex;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedToolIndex = index;
                        // Resetear evaluación seleccionada al cambiar de herramienta
                        _selectedEvaluationId = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF636366) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                            : null,
                      ),
                      child: Text(
                        tool.shortName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botón analizar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _runAnalysis,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome, size: 20),
              label: Text(_isAnalyzing ? 'Analizando...' : 'Ejecutar Análisis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisHeader(bool isDark) {
    return const SizedBox.shrink();
  }

  Widget _buildNoResultsCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.psychology,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Sin análisis aún',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Presiona "Ejecutar Análisis" para comenzar',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF007AFF).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Analizando datos clínicos...',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiResultCard(bool isDark) {
    // Filtrar evaluaciones por la herramienta seleccionada
    final selectedTool = _aiTools[_selectedToolIndex];
    final filteredEvaluations = _evaluations
        .where((e) => e.aiToolId == selectedTool.aiToolId)
        .toList();
    
    if (filteredEvaluations.isEmpty) {
      return _buildNoResultsCard(isDark);
    }
    
    // Mostrar la evaluación más reciente de la herramienta seleccionada
    final evaluation = filteredEvaluations.last;
    final result = AiDiagnosisResult.fromAiResult(evaluation.aiResult);
    final toolName = selectedTool.shortName;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Barra de gradiente
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF007AFF), Colors.purple[400]!],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con badge y confianza
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  toolName,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF007AFF),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimeAgo(evaluation.evaluationDate),
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.diagnosis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      
                      // Porcentaje de confianza
                      Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF22C55E).withOpacity(0.3),
                                width: 3,
                              ),
                              color: const Color(0xFF22C55E).withOpacity(0.05),
                            ),
                            child: Center(
                              child: Text(
                                '${result.confidencePercent}%',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confianza',
                            style: GoogleFonts.notoSans(
                              fontSize: 10,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Razonamiento
                  _buildSection(
                    'RAZONAMIENTO',
                    Icons.psychology,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900]!.withOpacity(0.5) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                        ),
                      ),
                      child: Text(
                        result.reasoning,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  // Plan sugerido
                  _buildSection(
                    'PLAN SUGERIDO',
                    Icons.medical_services,
                    Column(
                      children: result.suggestedPlan.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFF007AFF),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    isDark,
                  ),
                ],
              ),
            ),
            
            // Footer con acciones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252529) : Colors.grey[50],
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.content_copy, size: 16, color: const Color(0xFF007AFF)),
                    label: Text(
                      'Copiar Texto',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.thumb_down, size: 16, color: Colors.grey[500]),
                    label: Text(
                      'Reportar Error',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  /// Formatear tiempo transcurrido
  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Reciente';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      return 'Hace ${(difference.inDays / 7).floor()} sem';
    }
  }

  Widget _buildSelectionSection(bool isDark) {
    // Mostrar TODAS las evaluaciones (ChatGPT y Copilot) para que el usuario pueda elegir
    if (_evaluations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check, color: const Color(0xFF007AFF)),
              const SizedBox(width: 8),
              Text(
                'Selección para Base de Datos',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Opciones de evaluación (TODAS las evaluaciones disponibles)
          ..._evaluations.asMap().entries.map((entry) {
            final index = entry.key;
            final eval = entry.value;
            final isSelected = _selectedEvaluationId == eval.evaluationId;
            final result = AiDiagnosisResult.fromAiResult(eval.aiResult);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedEvaluationId = eval.evaluationId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF007AFF) : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.1), blurRadius: 8)]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: eval.evaluationId!,
                        groupValue: _selectedEvaluationId,
                        onChanged: (v) => setState(() => _selectedEvaluationId = v),
                        activeColor: const Color(0xFF007AFF),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Opción ${String.fromCharCode(65 + index)}: ${eval.aiTool?.shortName ?? 'IA'}',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF22C55E).withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${result.confidencePercent}% Confianza',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? const Color(0xFF22C55E) : Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dx: ${result.diagnosis}',
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            if (isSelected && index == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.recommend, size: 12, color: const Color(0xFF007AFF)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Recomendado por sistema',
                                      style: GoogleFonts.notoSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF007AFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildJustificationSection(bool isDark) {
    final chips = ['Clínica Coincidente', 'Preferencia Terapéutica', 'Seguridad'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JUSTIFICACIÓN DE LA ELECCIÓN',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            
            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((chip) {
                final isSelected = _selectedJustificationChip == chip;
                return GestureDetector(
                  onTap: () => setState(() => _selectedJustificationChip = chip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF007AFF).withOpacity(0.1)
                          : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF007AFF).withOpacity(0.2) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      chip,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? const Color(0xFF007AFF) : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            
            // Textarea
            TextField(
              controller: _justificationController,
              maxLines: 3,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Escriba su razonamiento clínico...',
                hintStyle: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF101922) : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007AFF)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Info
            Row(
              children: [
                Icon(Icons.info, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  'Esta justificación se almacenará junto con is_selected.',
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1C1C1E) : Colors.white).withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!.withOpacity(0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSaving || _selectedEvaluationId == null ? null : _saveEvaluation,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving ? 'Guardando...' : 'Confirmar y Guardar Evaluación',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF007AFF).withOpacity(0.25),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}


