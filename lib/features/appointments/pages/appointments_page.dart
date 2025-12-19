import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/models/patient_treatment_model.dart';
import '../../../core/services/appointments_service.dart';
import '../../../core/providers/auth_store.dart';
import '../../../theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/progress_card.dart';
import 'new_appointment_page.dart';
import 'clinical_evaluation_page.dart';
import 'ai_diagnosis_page.dart';

/// Pantalla de gestión de citas para un tratamiento de paciente
class AppointmentsPage extends StatefulWidget {
  final int patientTreatmentId;
  final PatientTreatmentModel? treatment;

  const AppointmentsPage({
    super.key,
    required this.patientTreatmentId,
    this.treatment,
  });

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final AppointmentsService _appointmentsService = AppointmentsService();
  
  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> _filteredAppointments = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  int _selectedDayIndex = 3; // Día seleccionado por defecto (Jueves)

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obtener el token de autenticación
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      final appointments = await _appointmentsService.getByPatientTreatment(
        widget.patientTreatmentId,
        token: token,
      );
      
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _filteredAppointments = appointments; // Mostrar todas las citas por defecto
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

  // Filtrar citas según el mes seleccionado
  void _filterAppointmentsByMonth() {
    _filteredAppointments = _appointments.where((appointment) {
      // Normalizar fechas para comparar solo año y mes
      final appointmentYear = appointment.appointmentDate.year;
      final appointmentMonth = appointment.appointmentDate.month;
      
      return appointmentYear == _selectedMonth.year &&
             appointmentMonth == _selectedMonth.month;
    }).toList();
    
    // Ordenar por fecha
    _filteredAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  // Calcular progreso basado en citas completadas
  double get _progressPercentage {
    if (_appointments.isEmpty) return 0;
    final completed = _appointments.where(
      (a) => a.status == AppointmentStatus.completed,
    ).length;
    return (completed / _appointments.length) * 100;
  }

  int get _completedCount => _appointments.where(
    (a) => a.status == AppointmentStatus.completed,
  ).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final treatmentName = widget.treatment?.treatmentName ?? 'Espasticidad';
    final doctorName = widget.treatment?.doctorName ?? 'Dr. Especialista';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón de regreso y agregar
            _buildHeader(context, isDark),
            
            // Contenido principal
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorWidget()
                      : _buildContent(isDark, treatmentName, doctorName),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? AppTheme.backgroundDark.withOpacity(0.95)
            : AppTheme.backgroundLight.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón volver
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
              shape: const CircleBorder(),
            ),
          ),
          
          // Título centrado
          Expanded(
            child: Text(
              'Gestión de Citas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Botón agregar cita
          IconButton(
            onPressed: _navigateToNewAppointment,
            icon: const Icon(Icons.add, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: const CircleBorder(),
            ),
          ),
        ],
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
              onPressed: _loadAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, String treatmentName, String doctorName) {
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de título del tratamiento
            _buildTreatmentHeader(isDark, treatmentName, doctorName),
            const SizedBox(height: 24),
            
            // Tarjeta de progreso del ciclo
            ProgressCard(
              title: 'Ciclo de Rehabilitación',
              progress: _progressPercentage,
              currentSession: _completedCount,
              totalSessions: _appointments.length,
              nextReviewDate: _getNextReviewDate(),
            ),
            const SizedBox(height: 24),
            
            // Calendario semanal horizontal
            _buildWeeklyCalendar(isDark),
            const SizedBox(height: 24),
            
            // Lista de próximas citas
            _buildAppointmentsList(isDark),
            
            const SizedBox(height: 80), // Espacio para el bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentHeader(bool isDark, String treatmentName, String doctorName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge de analíticas activa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ANALÍTICAS ACTIVAS',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Título del tratamiento
        Text(
          'Tratamiento: $treatmentName',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        
        // Información del protocolo
        Text(
          'Protocolo #SP-${widget.patientTreatmentId} • $doctorName',
          style: TextStyle(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar(bool isDark) {
    final now = DateTime.now();
    final weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sab', 'Dom'];
    
    // Generar días de la semana actual
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del calendario
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getMonthName(now.month) + ' ${now.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _showFullCalendar(context, isDark),
              child: Text(
                'Ver calendario',
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Días de la semana
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final day = startOfWeek.add(Duration(days: index));
              final isSelected = index == _selectedDayIndex;
              final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
              final hasAppointment = _hasAppointmentOnDay(day);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Si ya está seleccionado, deseleccionar
                    if (isSelected) {
                      _selectedDayIndex = -1;
                      _selectedDate = null;
                      _filteredAppointments = _appointments;
                    } else {
                      _selectedDayIndex = index;
                      _selectedDate = day;
                      _filterAppointmentsByDate(day);
                    }
                  });
                },
                child: Container(
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primary
                        : (isDark ? AppTheme.cardDark : AppTheme.cardLight),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Opacity(
                    opacity: isPast && !isSelected ? 0.6 : 1.0,
                    child: Transform.scale(
                      scale: isSelected ? 1.05 : 1.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Nombre del día
                          Text(
                            weekDays[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : (isDark 
                                      ? AppTheme.textSecondaryDark 
                                      : AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // Número del día
                          Text(
                            day.day.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : AppTheme.textPrimary),
                            ),
                          ),
                          
                          // Indicador de cita
                          if (hasAppointment || isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white 
                                    : AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullCalendar(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) => FullCalendarModal(
        appointments: _appointments,
        selectedMonth: _selectedMonth,
        selectedDate: _selectedDate,
        onMonthChanged: (month) {
          setState(() {
            _selectedMonth = month;
            _selectedDate = null;
            _filterAppointmentsByMonth();
          });
        },
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
            _selectedDayIndex = -1; // Resetear selección semanal
            _filterAppointmentsByDate(date);
          });
          Navigator.pop(context);
        },
        isDark: isDark,
      ),
    );
  }

  void _filterAppointmentsByDate(DateTime date) {
    // Normalizar la fecha para comparar solo año, mes y día
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    _filteredAppointments = _appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );
      return appointmentDate.isAtSameMomentAs(normalizedDate);
    }).toList();
    
    _filteredAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  Widget _buildAppointmentsList(bool isDark) {
    final title = _selectedDate != null
        ? 'Citas del ${_selectedDate!.day} ${_getMonthName(_selectedDate!.month).substring(0, 3)}'
        : 'Próximas Citas';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la lista
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
            if (_selectedDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                    _selectedDayIndex = 3; // Resetear selección
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text(
                  'Ver todas',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de citas (mostrar todas si no hay filtro de día, o filtradas si hay)
        if (_selectedDate == null)
          // Mostrar todas las citas si no hay día seleccionado
          if (_appointments.isEmpty)
            _buildEmptyState()
          else
            ..._appointments.map((appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppointmentCard(
                appointment: appointment,
                onTap: () => _showAppointmentDetails(appointment),
              ),
            ))
        else
          // Mostrar citas filtradas por día
          if (_filteredAppointments.isEmpty)
            _buildEmptyState()
          else
            ..._filteredAppointments.map((appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppointmentCard(
                appointment: appointment,
                onTap: () => _showAppointmentDetails(appointment),
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay citas programadas',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona + para agregar una nueva cita',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  String? _getNextReviewDate() {
    final upcoming = _appointments.where(
      (a) => a.status == AppointmentStatus.scheduled && 
             a.appointmentDate.isAfter(DateTime.now()),
    ).toList();
    
    if (upcoming.isEmpty) return null;
    
    upcoming.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    final next = upcoming.first.appointmentDate;
    return '${next.day} ${_getMonthName(next.month).substring(0, 3)}';
  }

  bool _hasAppointmentOnDay(DateTime day) {
    // Normalizar la fecha para comparar solo año, mes y día
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    return _appointments.any((a) {
      final appointmentDate = DateTime(
        a.appointmentDate.year,
        a.appointmentDate.month,
        a.appointmentDate.day,
      );
      return appointmentDate.isAtSameMomentAs(normalizedDay);
    });
  }

  /// Navegar a la pantalla de crear nueva cita
  Future<void> _navigateToNewAppointment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewAppointmentPage(
          patientTreatmentId: widget.patientTreatmentId,
          treatment: widget.treatment,
        ),
      ),
    );

    // Si se creó la cita, recargar la lista
    if (result == true) {
      _loadAppointments();
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentDetailSheet(
        appointment: appointment,
        patientName: widget.treatment?.patientName,
        onStatusChanged: (newStatus) async {
          Navigator.pop(context);
          await _updateAppointmentStatus(appointment, newStatus);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteAppointment(appointment);
        },
        onStartEvaluation: () {
          Navigator.pop(context);
          _navigateToEvaluation(appointment);
        },
        onAiDiagnosis: () {
          Navigator.pop(context);
          _navigateToAiDiagnosis(appointment);
        },
      ),
    );
  }

  /// Navegar a la pantalla de evaluación clínica
  void _navigateToEvaluation(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicalEvaluationPage(
          appointment: appointment,
          patientName: widget.treatment?.patientName,
        ),
      ),
    );
  }

  /// Navegar a la pantalla de diagnóstico con IA
  void _navigateToAiDiagnosis(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiDiagnosisPage(
          appointment: appointment,
          patientName: widget.treatment?.patientName,
        ),
      ),
    );
  }

  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cita'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cita? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      await _appointmentsService.delete(
        appointment.appointmentId,
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateAppointmentStatus(
    AppointmentModel appointment,
    AppointmentStatus newStatus,
  ) async {
    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      await _appointmentsService.update(
        appointment.appointmentId,
        status: newStatus,
        token: token,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: ${newStatus.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Bottom sheet para ver detalles de una cita
class _AppointmentDetailSheet extends StatelessWidget {
  final AppointmentModel appointment;
  final String? patientName;
  final Function(AppointmentStatus) onStatusChanged;
  final VoidCallback onDelete;
  final VoidCallback onStartEvaluation;
  final VoidCallback onAiDiagnosis;

  const _AppointmentDetailSheet({
    required this.appointment,
    this.patientName,
    required this.onStatusChanged,
    required this.onDelete,
    required this.onStartEvaluation,
    required this.onAiDiagnosis,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Título
          Text(
            'Detalles de la Cita',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Info de la cita
          _buildInfoRow(
            'Fecha',
            _formatDate(appointment.appointmentDate),
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Estado',
            appointment.status.displayName,
            Icons.flag,
          ),
          if (appointment.notes != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Notas',
              appointment.notes!,
              Icons.notes,
            ),
          ],
          const SizedBox(height: 24),
          
          // Acciones
          Text(
            'Cambiar estado:',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppointmentStatus.values.map((status) {
              final isCurrentStatus = status == appointment.status;
              return FilterChip(
                label: Text(status.displayName),
                selected: isCurrentStatus,
                onSelected: isCurrentStatus 
                    ? null 
                    : (_) => onStatusChanged(status),
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                selectedColor: AppTheme.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Botón iniciar evaluación
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStartEvaluation,
              icon: const Icon(Icons.assignment),
              label: const Text('Iniciar Evaluación Clínica'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botón diagnóstico IA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAiDiagnosis,
              icon: Icon(Icons.auto_awesome, color: Colors.purple[400]),
              label: const Text('Diagnosticar con IA'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple[400],
                side: BorderSide(color: Colors.purple[400]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botón eliminar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Eliminar Cita'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Modal con calendario completo mensual
class FullCalendarModal extends StatefulWidget {
  final List<AppointmentModel> appointments;
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final Function(DateTime) onMonthChanged;
  final Function(DateTime) onDateSelected;
  final bool isDark;

  const FullCalendarModal({
    super.key,
    required this.appointments,
    required this.selectedMonth,
    this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.isDark,
  });

  @override
  State<FullCalendarModal> createState() => _FullCalendarModalState();
}

class _FullCalendarModalState extends State<FullCalendarModal> {
  late DateTime _currentMonth;
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedMonth;
  }
  
  @override
  void didUpdateWidget(FullCalendarModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMonth != oldWidget.selectedMonth) {
      _currentMonth = widget.selectedMonth;
    }
  }

  bool _hasAppointmentOnDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return widget.appointments.any((a) {
      final appointmentDate = DateTime(
        a.appointmentDate.year,
        a.appointmentDate.month,
        a.appointmentDate.day,
      );
      return appointmentDate.isAtSameMomentAs(normalizedDay);
    });
  }

  bool _isCurrentWeek(DateTime day) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return day.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           day.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    final daysToShow = <DateTime>[];
    
    // Días del mes anterior
    if (firstDayWeekday > 1) {
      final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      final daysInPreviousMonth = DateTime(previousMonth.year, previousMonth.month + 1, 0).day;
      for (int i = firstDayWeekday - 2; i >= 0; i--) {
        daysToShow.add(DateTime(previousMonth.year, previousMonth.month, daysInPreviousMonth - i));
      }
    }
    
    // Días del mes actual
    for (int day = 1; day <= daysInMonth; day++) {
      daysToShow.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }
    
    // Días del mes siguiente
    final remainingDays = 42 - daysToShow.length;
    for (int day = 1; day <= remainingDays; day++) {
      daysToShow.add(DateTime(_currentMonth.year, _currentMonth.month + 1, day));
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: MediaQuery.of(context).size.height * 0.15, // Posición más arriba
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle mejorado
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            
            // Header con navegación mejorado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón mes anterior
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                        });
                        widget.onMonthChanged(_currentMonth);
                      },
                      icon: Icon(Icons.chevron_left, color: AppTheme.primary, size: 24),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  
                  // Mes y año
                  Column(
                    children: [
                      Text(
                        _getMonthName(_currentMonth.month).toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : AppTheme.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentMonth.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Botón mes siguiente
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                        });
                        widget.onMonthChanged(_currentMonth);
                      },
                      icon: Icon(Icons.chevron_right, color: AppTheme.primary, size: 24),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          
          // Días de la semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: weekDays.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Grid de días
          SizedBox(
            height: 280, // Altura fija para el calendario
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.1,
                ),
                itemCount: daysToShow.length,
                itemBuilder: (context, index) {
                  final day = daysToShow[index];
                  final isCurrentMonth = day.month == _currentMonth.month;
                  final isToday = day.year == now.year && 
                                 day.month == now.month && 
                                 day.day == now.day;
                  final isSelected = widget.selectedDate != null &&
                                   day.year == widget.selectedDate!.year &&
                                   day.month == widget.selectedDate!.month &&
                                   day.day == widget.selectedDate!.day;
                  final isPast = day.isBefore(DateTime(now.year, now.month, now.day)) && !isToday;
                  final hasAppointment = _hasAppointmentOnDay(day);
                  final isInCurrentWeek = _isCurrentWeek(day) && isCurrentMonth;
                  
                  return GestureDetector(
                    onTap: isCurrentMonth ? () {
                      widget.onDateSelected(day);
                    } : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : (isInCurrentWeek && !isSelected
                                ? AppTheme.primary.withOpacity(0.1)
                                : (isToday && !isSelected
                                    ? AppTheme.primary.withOpacity(0.15)
                                    : Colors.transparent)),
                        borderRadius: BorderRadius.circular(8),
                        border: isInCurrentWeek && !isSelected
                            ? Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5)
                            : (isToday && !isSelected
                                ? Border.all(color: AppTheme.primary, width: 2)
                                : null),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: isCurrentMonth ? 13 : 11,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : (isCurrentMonth ? FontWeight.w600 : FontWeight.w400),
                              color: !isCurrentMonth
                                  ? (widget.isDark ? Colors.grey[700] : Colors.grey[300])
                                  : (isSelected
                                      ? Colors.white
                                      : (isPast
                                          ? (widget.isDark ? Colors.grey[500] : Colors.grey[400])
                                          : (widget.isDark ? Colors.white : AppTheme.textPrimary))),
                            ),
                          ),
                          if (hasAppointment && isCurrentMonth)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else if (isCurrentMonth)
                            const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    ),
    );
  }
}

