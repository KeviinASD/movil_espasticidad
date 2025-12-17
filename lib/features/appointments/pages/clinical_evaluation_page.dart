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

      // Cargar respuestas existentes para esta cita
      final existingAnswers = await _answersService.getByAppointment(
        widget.appointment.appointmentId,
        token: token,
      );

      // Crear controladores y cargar respuestas existentes
      final controllers = <int, TextEditingController>{};
      final answers = <int, double?>{};

      for (final question in questions) {
        controllers[question.questionId] = TextEditingController();
        
        // Buscar respuesta existente
        final existing = existingAnswers.firstWhere(
          (a) => a.questionId == question.questionId,
          orElse: () => AppointmentAnswerModel(
            appointmentId: widget.appointment.appointmentId,
            questionId: question.questionId,
          ),
        );
        
        if (existing.numericValue != null) {
          controllers[question.questionId]!.text = existing.numericValue.toString();
          answers[question.questionId] = existing.numericValue;
        }
      }

      if (!mounted) return;
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

      // Guardar cada respuesta
      for (final question in _questions) {
        final value = _answers[question.questionId];
        if (value != null) {
          await _answersService.create(
            appointmentId: widget.appointment.appointmentId,
            questionId: question.questionId,
            numericValue: value,
            token: token,
          );
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
          
          // Sección de signos vitales
          _buildVitalsSection(isDark),
          
          // Divisor
          _buildDivider(isDark),
          
          // Sección de espasmos
          _buildSpasmsSection(isDark),
          
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

  Widget _buildDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      height: 1,
      color: isDark ? const Color(0xFF1e293b) : const Color(0xFFe2e8f0),
    );
  }

  Widget _buildVitalsSection(bool isDark) {
    // Filtrar preguntas de signos vitales (peso y ritmo)
    final vitalsQuestions = _questions.where((q) {
      final text = q.questionText.toLowerCase();
      return text.contains('peso') || text.contains('ritmo') || text.contains('cardíaco');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppTheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Signos Vitales',
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
        
        // Grid de inputs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: vitalsQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < vitalsQuestions.length - 1 ? 16 : 0,
                  ),
                  child: _buildInputField(question, isDark),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpasmsSection(bool isDark) {
    // Filtrar pregunta de espasmos
    final spasmsQuestion = _questions.where((q) {
      final text = q.questionText.toLowerCase();
      return text.contains('espasmo');
    }).toList();

    if (spasmsQuestion.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.waves,
                color: AppTheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Frecuencia de Espasmos',
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
        
        // Input de espasmos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSpasmsInput(spasmsQuestion.first, isDark),
        ),
      ],
    );
  }

  Widget _buildInputField(QuestionModel question, bool isDark) {
    final controller = _controllers[question.questionId]!;
    final labelText = _getShortLabel(question.questionText);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1c2630) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: question.inputHint,
              hintStyle: GoogleFonts.spaceGrotesk(
                color: isDark ? const Color(0xFF475569) : const Color(0xFF94a3b8),
              ),
              suffixIcon: _buildSuffixIcon(question, isDark),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) {
              final numValue = double.tryParse(value);
              setState(() {
                _answers[question.questionId] = numValue;
                _updateProgress();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpasmsInput(QuestionModel question, bool isDark) {
    final controller = _controllers[question.questionId]!;
    final currentValue = _answers[question.questionId]?.toInt() ?? 0;
    
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
        children: [
          // Header con valor actual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Espasmos por día',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF475569),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
                  ),
                ),
                child: Text(
                  '$currentValue',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Input numérico grande
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
                prefixIcon: Icon(
                  Icons.waves,
                  color: AppTheme.primary,
                  size: 24,
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
                final numValue = double.tryParse(value);
                setState(() {
                  _answers[question.questionId] = numValue;
                  _updateProgress();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon(QuestionModel question, bool isDark) {
    final text = question.questionText.toLowerCase();
    
    if (text.contains('ritmo') || text.contains('cardíaco')) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          Icons.favorite,
          color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
          size: 20,
        ),
      );
    }
    
    return null;
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

  String _getShortLabel(String questionText) {
    final text = questionText.toLowerCase();
    if (text.contains('peso')) return 'Peso (kg)';
    if (text.contains('ritmo') || text.contains('cardíaco')) return 'Ritmo (bpm)';
    if (text.contains('espasmo')) return 'Espasmos/día';
    return questionText;
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
