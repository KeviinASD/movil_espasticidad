import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/models/patient_treatment_model.dart';
import '../../../core/services/appointments_service.dart';
import '../../../core/providers/auth_store.dart';
import '../../../theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/calendar_day_widget.dart';
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
  bool _isLoading = true;
  String? _error;
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
            
            // Calendario horizontal
            _buildCalendarSection(isDark),
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
        // Badge de investigación activa
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
                'INVESTIGACIÓN ACTIVA',
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

  Widget _buildCalendarSection(bool isDark) {
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
              onPressed: () {
                // TODO: Ver calendario completo
              },
              child: const Text('Ver calendario'),
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
              
              return CalendarDayWidget(
                dayName: weekDays[index],
                dayNumber: day.day,
                isSelected: isSelected,
                isPast: isPast,
                hasAppointment: hasAppointment,
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la lista
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximas Citas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Mostrar filtros
              },
              style: TextButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(
                'Filtrar',
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de citas
        if (_appointments.isEmpty)
          _buildEmptyState()
        else
          ..._appointments.map((appointment) => Padding(
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
    return _appointments.any((a) =>
        a.appointmentDate.year == day.year &&
        a.appointmentDate.month == day.month &&
        a.appointmentDate.day == day.day);
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

