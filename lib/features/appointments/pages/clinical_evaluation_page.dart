import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/models/appointment_answer_model.dart';
import '../../../core/services/questions_service.dart';
import '../../../core/services/appointment_answers_service.dart';
import '../../../core/providers/auth_store.dart';
import '../../../theme/app_theme.dart';

/// Pantalla de evaluación clínica para una cita
class ClinicalEvaluationPage extends StatefulWidget {
  final AppointmentModel appointment;
  final String? patientName;

  const ClinicalEvaluationPage({
    super.key,
    required this.appointment,
    this.patientName,
  });

  @override
  State<ClinicalEvaluationPage> createState() => _ClinicalEvaluationPageState();
}

class _ClinicalEvaluationPageState extends State<ClinicalEvaluationPage> {
  final QuestionsService _questionsService = QuestionsService();
  final AppointmentAnswersService _answersService = AppointmentAnswersService();

  List<QuestionModel> _questions = [];
  Map<int, TextEditingController> _controllers = {};
  Map<int, double?> _answers = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
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

      // Cargar preguntas
      final questions = await _questionsService.getAll(token: token);
      
      // Obtener IDs de preguntas válidas
      final validQuestionIds = questions.map((q) => q.questionId).toSet();
      print('📋 Preguntas válidas cargadas: ${validQuestionIds.length}');
      for (final q in questions) {
        print('  - ID: ${q.questionId}, Texto: ${q.questionText}');
      }

      // Cargar respuestas existentes para esta cita
      final allExistingAnswers = await _answersService.getByAppointment(
        widget.appointment.appointmentId,
        token: token,
      );
      
      // Filtrar solo respuestas que tienen preguntas válidas
      final existingAnswers = allExistingAnswers.where(
        (a) => validQuestionIds.contains(a.questionId),
      ).toList();
      
      // Detectar respuestas huérfanas
      final orphanAnswers = allExistingAnswers.where(
        (a) => !validQuestionIds.contains(a.questionId),
      ).toList();
      
      if (orphanAnswers.isNotEmpty) {
        print('⚠️ Se encontraron ${orphanAnswers.length} respuesta(s) huérfana(s) (preguntas eliminadas):');
        for (final orphan in orphanAnswers) {
          print('  - Answer ID: ${orphan.answerId}, Question ID: ${orphan.questionId} (ya no existe)');
        }
      }

      // Crear controladores y cargar respuestas existentes
      final controllers = <int, TextEditingController>{};
      final answers = <int, double?>{};

      for (final question in questions) {
        final questionText = question.questionText.toLowerCase();
        final isMas = questionText.contains('ashworth') || questionText.contains('mas');
        
        // Solo crear controlador de texto si NO es MAS (MAS usa botones, no TextField)
        if (!isMas) {
          // Crear un controlador único para cada pregunta (excepto MAS)
          controllers[question.questionId] = TextEditingController();
        }
        
        // Debug: mostrar qué pregunta se está procesando
        print('📝 Procesando pregunta ID: ${question.questionId}, Texto: ${question.questionText}, es MAS: $isMas');
        
        // Buscar respuesta existente para esta pregunta específica
        final existing = existingAnswers.where(
          (a) => a.questionId == question.questionId,
        ).firstOrNull;
        
        // Solo cargar valores si existen y no son null
        if (existing != null && existing.numericValue != null) {
          // Solo actualizar controlador si existe (no para MAS)
          if (!isMas && controllers.containsKey(question.questionId)) {
            controllers[question.questionId]!.text = existing.numericValue.toString();
          }
          answers[question.questionId] = existing.numericValue;
          print('  ✅ Cargado valor existente: ${existing.numericValue}');
        } else {
          // Inicializar como null para evitar valores pre-poblados
          answers[question.questionId] = null;
          // Asegurar que el controlador esté vacío si existe
          if (!isMas && controllers.containsKey(question.questionId)) {
            controllers[question.questionId]!.clear();
          }
          print('  ⚪ Sin valor (null)');
        }
      }

      if (!mounted) return;
      
      // Debug: verificar que se cargaron las 4 preguntas
      if (questions.length < 4) {
        print('⚠️ Advertencia: Se esperaban 4 preguntas pero solo se cargaron ${questions.length}');
        for (final q in questions) {
          print('  - ${q.questionText}');
        }
      }
      
      setState(() {
        _questions = questions;
        _controllers = controllers;
        _answers = answers;
        _isLoading = false;
        _updateProgress();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _updateProgress() {
    if (_questions.isEmpty) {
      _progress = 0;
      return;
    }
    
    final answered = _answers.values.where((v) => v != null).length;
    setState(() {
      _progress = (answered / _questions.length) * 100;
    });
  }

  Future<void> _saveAnswers() async {
    setState(() => _isSaving = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      // Cargar respuestas existentes para actualizar en lugar de crear duplicados
      final existingAnswers = await _answersService.getByAppointment(
        widget.appointment.appointmentId,
        token: token,
      );

      // Obtener lista de IDs de preguntas válidas
      final validQuestionIds = _questions.map((q) => q.questionId).toSet();
      
      // Filtrar respuestas existentes para solo usar las que tienen preguntas válidas
      final validExistingAnswers = existingAnswers.where(
        (a) => validQuestionIds.contains(a.questionId),
      ).toList();
      
      // Guardar o actualizar cada respuesta
      for (final question in _questions) {
        // Validar que la pregunta existe en la lista cargada
        if (!validQuestionIds.contains(question.questionId)) {
          print('⚠️ Advertencia: Pregunta con ID ${question.questionId} no es válida, saltando...');
          continue;
        }
        
        final value = _answers[question.questionId];
        
        // Buscar respuesta existente para esta pregunta (solo de las válidas)
        final existing = validExistingAnswers.firstWhere(
          (a) => a.questionId == question.questionId,
          orElse: () => AppointmentAnswerModel(
            appointmentId: widget.appointment.appointmentId,
            questionId: question.questionId,
          ),
        );

        if (value != null) {
          // Si existe una respuesta, actualizarla; si no, crearla
          if (existing.answerId != null) {
            await _answersService.update(
              existing.answerId!,
              numericValue: value,
              token: token,
            );
          } else {
            await _answersService.create(
              appointmentId: widget.appointment.appointmentId,
              questionId: question.questionId,
              numericValue: value,
              token: token,
            );
          }
        } else if (existing.answerId != null) {
          // Si el valor es null pero existe una respuesta, eliminarla
          await _answersService.delete(existing.answerId!, token: token);
        }
      }
      
      // Limpiar respuestas huérfanas (respuestas con questionId que ya no existe)
      final orphanAnswers = existingAnswers.where(
        (a) => !validQuestionIds.contains(a.questionId),
      ).toList();
      
      for (final orphan in orphanAnswers) {
        if (orphan.answerId != null) {
          print('🗑️ Eliminando respuesta huérfana (questionId: ${orphan.questionId} ya no existe)');
          try {
            await _answersService.delete(orphan.answerId!, token: token);
          } catch (e) {
            print('⚠️ Error al eliminar respuesta huérfana: $e');
          }
        }
      }

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
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header con blur
            _buildHeader(context, isDark),
            
            // Contenido
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
      // Botón flotante fijo
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1e293b) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Botón volver
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1c2630) : Colors.grey[100],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
              ),
            ),
            
            // Título centrado
            Expanded(
              child: Text(
                'Evaluación Clínica',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Botón guardar
            TextButton(
              onPressed: _isSaving ? null : _saveAnswers,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Guardar',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
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
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de contexto del paciente
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPatientContextCard(isDark, patientName),
          ),
          
          // Barra de progreso
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProgressBar(isDark),
          ),
          
          const SizedBox(height: 8),
          
          // Sección de indicadores
          _buildIndicatorsSection(isDark),
          
          const SizedBox(height: 120), // Espacio para el botón fijo
        ],
      ),
    );
  }

  Widget _buildPatientContextCard(bool isDark, String patientName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar con imagen placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.15),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : Colors.grey[200]!,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(patientName),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        patientName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10b981).withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Activo',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF34d399) : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.appointment.appointmentId} • Cita: ${_formatDate(widget.appointment.appointmentDate)}',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso de la evaluación',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF475569),
              ),
            ),
            Text(
              '${_progress.toInt()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: MediaQuery.of(context).size.width * (_progress / 100) * 0.85,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildIndicatorsSection(bool isDark) {
    // Obtener cada indicador por su nombre (búsqueda más flexible)
    QuestionModel? masQuestion;
    QuestionModel? spasmsQuestion;
    QuestionModel? hReflexQuestion;
    QuestionModel? srtQuestion;
    QuestionModel? heartRateQuestion;
    QuestionModel? weightQuestion;

    for (final q in _questions) {
      final text = q.questionText.toLowerCase();
      
      // MAS: busca "ashworth" o "mas" (no case sensitive)
      if ((text.contains('ashworth') || text.contains('mas')) && masQuestion == null) {
        masQuestion = q;
      } 
      // Espasmos: busca "espasmo" o "frecuencia" (y que no sea MAS)
      else if ((text.contains('espasmo') || text.contains('frecuencia')) && 
               !text.contains('ashworth') && 
               !text.contains('mas') &&
               spasmsQuestion == null) {
        spasmsQuestion = q;
      } 
      // H-Reflex: busca "h-reflex", "hmax", "mmax", o "h max" o "m max"
      else if ((text.contains('h-reflex') || 
                text.contains('hmax') || 
                text.contains('mmax') ||
                text.contains('h max') ||
                text.contains('m max') ||
                text.contains('h/m')) && 
               hReflexQuestion == null) {
        hReflexQuestion = q;
      } 
      // SRT: busca "stretch", "srt", o "threshold"
      else if ((text.contains('stretch') || 
                text.contains('srt') || 
                text.contains('threshold')) && 
               srtQuestion == null) {
        srtQuestion = q;
      }
      // Ritmo cardíaco: busca "ritmo", "cardiaco", "cardíaco", "bpm"
      else if ((text.contains('ritmo') || 
                text.contains('cardiaco') || 
                text.contains('cardíaco') ||
                text.contains('bpm')) && 
               heartRateQuestion == null) {
        heartRateQuestion = q;
      }
      // Peso: busca "peso" o "kg"
      else if ((text.contains('peso') || text.contains('kg')) && 
               !text.contains('ritmo') &&
               !text.contains('cardiaco') &&
               !text.contains('cardíaco') &&
               !text.contains('bpm') &&
               weightQuestion == null) {
        weightQuestion = q;
      }
    }

    // Si no se encontraron por nombre, usar las primeras preguntas en orden
    // Esto asegura que siempre se muestren los indicadores si existen
    int fallbackIndex = 0;
    if (masQuestion == null && _questions.isNotEmpty) {
      masQuestion = _questions[fallbackIndex++];
    }
    if (spasmsQuestion == null && fallbackIndex < _questions.length) {
      spasmsQuestion = _questions[fallbackIndex++];
    }
    if (hReflexQuestion == null && fallbackIndex < _questions.length) {
      hReflexQuestion = _questions[fallbackIndex++];
    }
    if (srtQuestion == null && fallbackIndex < _questions.length) {
      srtQuestion = _questions[fallbackIndex++];
    }
    if (heartRateQuestion == null && fallbackIndex < _questions.length) {
      heartRateQuestion = _questions[fallbackIndex++];
    }
    if (weightQuestion == null && fallbackIndex < _questions.length) {
      weightQuestion = _questions[fallbackIndex++];
    }
    
    // Debug: mostrar qué preguntas se asignaron con sus IDs
    print('📊 Indicadores asignados:');
    print('  MAS (ID: ${masQuestion?.questionId}): ${masQuestion?.questionText ?? "NO ENCONTRADO"}');
    print('  Espasmos (ID: ${spasmsQuestion?.questionId}): ${spasmsQuestion?.questionText ?? "NO ENCONTRADO"}');
    print('  H-Reflex (ID: ${hReflexQuestion?.questionId}): ${hReflexQuestion?.questionText ?? "NO ENCONTRADO"}');
    print('  SRT (ID: ${srtQuestion?.questionId}): ${srtQuestion?.questionText ?? "NO ENCONTRADO"}');
    print('  Ritmo cardíaco (ID: ${heartRateQuestion?.questionId}): ${heartRateQuestion?.questionText ?? "NO ENCONTRADO"}');
    print('  Peso (ID: ${weightQuestion?.questionId}): ${weightQuestion?.questionText ?? "NO ENCONTRADO"}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.assessment,
                color: AppTheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Indicadores Cuantitativos',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // 1. Modified Ashworth Scale (MAS)
        if (masQuestion != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMasInput(masQuestion, isDark),
          ),
          const SizedBox(height: 16),
        ],
        
        // 2. Frecuencia de espasmos
        if (spasmsQuestion != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSpasmsInput(spasmsQuestion, isDark),
          ),
          const SizedBox(height: 16),
        ],
        
        // 3. H-Reflex Ratio
        if (hReflexQuestion != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHReflexInput(hReflexQuestion, isDark),
          ),
          const SizedBox(height: 16),
        ],
        
        // 4. Stretch Reflex Threshold (SRT)
        if (srtQuestion != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSrtInput(srtQuestion, isDark),
          ),
          const SizedBox(height: 16),
        ],
        
        // 5. Ritmo cardíaco
        if (heartRateQuestion != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHeartRateInput(heartRateQuestion, isDark),
          ),
          const SizedBox(height: 16),
        ],
        
        // 6. Peso
        if (weightQuestion != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildWeightInput(weightQuestion, isDark),
          ),
        ],
      ],
    );
  }


  Widget _buildMasInput(QuestionModel question, bool isDark) {
    final currentValue = _answers[question.questionId];
    final masValues = [0.0, 1.0, 1.5, 2.0, 3.0, 4.0];
    
    // Debug: verificar la pregunta
    print('🔵 _buildMasInput - ID: ${question.questionId}, Texto: ${question.questionText}');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Modified Ashworth Scale (MAS)',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Grado de aumento del tono muscular',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: masValues.map((value) {
              final isSelected = currentValue == value;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    print('🔵 MAS botón tocado - Valor: $value, Question ID: ${question.questionId}');
                    setState(() {
                      final questionId = question.questionId;
                      
                      // Actualizar el valor directamente sin validación estricta
                      // porque este método solo se llama para MAS
                      print('🔵 MAS seleccionado - ID: $questionId, Valor: $value');
                      _answers[questionId] = value;
                      
                      print('✅ Valor actualizado. Estado de _answers:');
                      _answers.forEach((id, val) {
                        print('  ID $id: $val');
                      });
                      
                      _updateProgress();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  splashColor: AppTheme.primary.withOpacity(0.2),
                  highlightColor: AppTheme.primary.withOpacity(0.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : (isDark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      value.toString(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpasmsInput(QuestionModel question, bool isDark) {
    final controller = _controllers[question.questionId]!;
    
    // Debug: verificar que el controlador es correcto
    print('🟢 Espasmos - ID: ${question.questionId}, Texto: ${question.questionText}');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.waves, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Frecuencia de Espasmos Musculares',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Número de espasmos por día (0 - >50)',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8),
                  fontSize: 24,
                ),
                suffixText: '/día',
                suffixStyle: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  final questionId = question.questionId;
                  final questionText = question.questionText.toLowerCase();
                  
                  // Verificar que estamos actualizando el campo correcto
                  if (!questionText.contains('espasmo') && !questionText.contains('frecuencia')) {
                    print('⚠️ ERROR: Intentando actualizar campo incorrecto!');
                    return;
                  }
                  
                  print('🟡 Espasmos cambiado - ID: $questionId, Valor: $value');
                  
                  // Solo actualizar si el valor es válido o está vacío
                  if (value.isEmpty) {
                    _answers[questionId] = null;
                  } else {
                    final numValue = int.tryParse(value);
                    if (numValue != null) {
                      _answers[questionId] = numValue.toDouble();
                      print('✅ Espasmos actualizado correctamente: $numValue');
                    }
                  }
                  _updateProgress();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHReflexInput(QuestionModel question, bool isDark) {
    final controller = _controllers[question.questionId]!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'H-Reflex Ratio (Hmax / Mmax)',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Excitabilidad de motoneuronas espinales (0.0 - 1.0)',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8),
                  fontSize: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  final questionId = question.questionId;
                  final questionText = question.questionText.toLowerCase();
                  
                  // Verificar que estamos actualizando H-Reflex
                  if (!questionText.contains('h-reflex') && 
                      !questionText.contains('hmax') && 
                      !questionText.contains('mmax')) {
                    print('⚠️ ERROR: Intentando actualizar H-Reflex en pregunta incorrecta!');
                    return;
                  }
                  
                  print('🟣 H-Reflex cambiado - ID: $questionId, Valor: $value');
                  
                  if (value.isEmpty) {
                    _answers[questionId] = null;
                  } else {
                    final numValue = double.tryParse(value);
                    if (numValue != null && numValue >= 0.0 && numValue <= 1.0) {
                      _answers[questionId] = numValue;
                    }
                  }
                  _updateProgress();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSrtInput(QuestionModel question, bool isDark) {
    final controller = _controllers[question.questionId]!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Stretch Reflex Threshold (SRT)',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Velocidad mínima de estiramiento (10 - 300 °/s)',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8),
                  fontSize: 20,
                ),
                suffixText: '°/s',
                suffixStyle: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  final questionId = question.questionId;
                  final questionText = question.questionText.toLowerCase();
                  
                  // Verificar que estamos actualizando SRT
                  if (!questionText.contains('stretch') && 
                      !questionText.contains('srt') && 
                      !questionText.contains('threshold')) {
                    print('⚠️ ERROR: Intentando actualizar SRT en pregunta incorrecta!');
                    return;
                  }
                  
                  print('🟠 SRT cambiado - ID: $questionId, Valor: $value');
                  
                  if (value.isEmpty) {
                    _answers[questionId] = null;
                  } else {
                    final numValue = double.tryParse(value);
                    if (numValue != null && numValue >= 10.0 && numValue <= 300.0) {
                      _answers[questionId] = numValue;
                    }
                  }
                  _updateProgress();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateInput(QuestionModel question, bool isDark) {
    final controller = _controllers[question.questionId];
    if (controller == null) {
      print('🔴 ERROR: Controlador de Ritmo cardíaco no encontrado para ID: ${question.questionId}');
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ritmo Cardíaco',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Frecuencia cardíaca en reposo (40 - 200 bpm)',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8),
                  fontSize: 24,
                ),
                suffixText: 'bpm',
                suffixStyle: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  final questionId = question.questionId;
                  final questionText = question.questionText.toLowerCase();

                  // Verificar que estamos actualizando Ritmo cardíaco
                  if (!questionText.contains('ritmo') &&
                      !questionText.contains('cardiaco') &&
                      !questionText.contains('cardíaco') &&
                      !questionText.contains('bpm')) {
                    print('⚠️ ERROR: Intentando actualizar Ritmo cardíaco en pregunta incorrecta!');
                    return;
                  }

                  print('❤️ Ritmo cardíaco cambiado - ID: $questionId, Valor: $value');

                  if (value.isEmpty) {
                    _answers[questionId] = null;
                  } else {
                    final numValue = int.tryParse(value);
                    if (numValue != null && numValue >= 40 && numValue <= 200) {
                      _answers[questionId] = numValue.toDouble();
                    }
                  }
                  _updateProgress();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInput(QuestionModel question, bool isDark) {
    final controller = _controllers[question.questionId];
    if (controller == null) {
      print('🔴 ERROR: Controlador de Peso no encontrado para ID: ${question.questionId}');
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Peso',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Peso corporal (20 - 200 kg)',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8),
                  fontSize: 24,
                ),
                suffixText: 'kg',
                suffixStyle: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  final questionId = question.questionId;
                  final questionText = question.questionText.toLowerCase();

                  // Verificar que estamos actualizando Peso
                  if (!questionText.contains('peso') && !questionText.contains('kg')) {
                    print('⚠️ ERROR: Intentando actualizar Peso en pregunta incorrecta!');
                    return;
                  }

                  print('⚖️ Peso cambiado - ID: $questionId, Valor: $value');

                  if (value.isEmpty) {
                    _answers[questionId] = null;
                  } else {
                    final numValue = double.tryParse(value);
                    if (numValue != null && numValue >= 20.0 && numValue <= 200.0) {
                      _answers[questionId] = numValue;
                    }
                  }
                  _updateProgress();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight).withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAnswers,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: AppTheme.primary.withOpacity(0.3),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Guardar Respuestas',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && 
                    date.month == now.month && 
                    date.day == now.day;
    
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    if (isToday) {
      return 'Hoy, $hour12:$minute $period';
    }
    
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]}, $hour12:$minute $period';
  }
}
