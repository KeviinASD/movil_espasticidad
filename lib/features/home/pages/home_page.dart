import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/auth_store.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/services/appointments_service.dart';
import '../../../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../../appointments/widgets/appointment_card.dart';
import '../../patients/pages/new_patient_page.dart';
import '../../appointments/pages/clinical_evaluation_page.dart';
import '../../appointments/pages/ai_diagnosis_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppointmentsService _appointmentsService = AppointmentsService();
  List<AppointmentModel> _upcomingAppointments = [];
  bool _isLoadingAppointments = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUpcomingAppointments();
    });
  }

  Future<void> _loadUpcomingAppointments() async {
    final authStore = context.read<AuthStore>();
    final token = authStore.token;
    final doctorId = authStore.currentUser?.id;

    if (token == null || doctorId == null) return;

    setState(() => _isLoadingAppointments = true);

    try {
      final appointments = await _appointmentsService.getUpcomingAppointments(
        doctorId: doctorId,
        token: token,
      );

      setState(() {
        _upcomingAppointments = appointments.take(3).toList(); // Solo las primeras 3
        _isLoadingAppointments = false;
      });
    } catch (e) {
      setState(() => _isLoadingAppointments = false);
      if (mounted) {
        debugPrint('Error al cargar citas: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con bienvenida y perfil
              _buildHeader(context, authStore, isDark),
              const SizedBox(height: 24),

              // Cards de estadísticas
              _buildStatsSection(),
              const SizedBox(height: 32),

              // Acceso Rápido
              Text(
                'Acceso Rápido',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Card grande - Investigar Tratamientos
              QuickActionCard(
                icon: Icons.science,
                iconColor: Colors.white,
                title: 'Investigar Tratamientos',
                subtitle: 'Base de datos de Ensayos',
                isLarge: true,
                onTap: () {
                  // TODO: Navegar a tratamientos
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente')),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Cards pequeñas
              Row(
                children: [
                  Expanded(
                    child: _buildSmallActionCard(
                      context,
                      icon: Icons.person_add,
                      color: const Color(0xFF9D4EDD),
                      title: 'Nuevo\nPaciente',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewPatientPage(),
                          ),
                        );
                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Paciente creado exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallActionCard(
                      context,
                      icon: Icons.assessment,
                      color: const Color(0xFFFF9800),
                      title: 'Escala\nAshworth',
                      onTap: () {
                        // TODO: Navegar a escala
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')),
                        );
                      },
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Progreso General
              _buildProgressSection(isDark),
              const SizedBox(height: 32),

              // Citas Próximas
              _buildUpcomingAppointments(context, authStore, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthStore authStore, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido,',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color:
                      isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authStore.doctorName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary,
              child: Text(
                authStore.initials,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
          onPressed: () {
            // TODO: Navegar a notificaciones
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {
        'icon': Icons.people,
        'color': AppTheme.primary,
        'title': 'PACIENTES',
        'value': '12',
      },
      {
        'icon': Icons.monitor_heart,
        'color': const Color(0xFFE53935),
        'title': 'CRÍTICOS',
        'value': '3',
      },
      {
        'icon': Icons.science,
        'color': const Color(0xFF00BFA5),
        'title': 'ENSAYOS',
        'value': '5',
      },
      /* {
        'icon': Icons.assignment,
        'color': const Color(0xFFFF9800),
        'title': 'TRATAMIENTOS',
        'value': '8',
      },
      {
        'icon': Icons.calendar_today,
        'color': const Color(0xFF9C27B0),
        'title': 'CITAS HOY',
        'value': '2',
      }, */
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            width: 140,
            margin: EdgeInsets.only(
              right: index < stats.length - 1 ? 12 : 0,
            ),
            child: StatCard(
              icon: stat['icon'] as IconData,
              iconColor: stat['color'] as Color,
              title: stat['title'] as String,
              value: stat['value'] as String,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmallActionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso General',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Color(0xFF4CAF50),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+5%',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Basado en % de progreso (Citas)',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '78%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Recuperación Media',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color:
                        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['SEM 1', 'SEM 2', 'SEM 3', 'SEM 4'];
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: GoogleFonts.notoSans(
                                fontSize: 10,
                                color: isDark
                                    ? AppTheme.textTertiary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 3),
                      FlSpot(2, 2.5),
                      FlSpot(3, 4),
                    ],
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primary,
                          strokeWidth: 2,
                          strokeColor: isDark
                              ? AppTheme.backgroundDark
                              : AppTheme.backgroundLight,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments(
    BuildContext context,
    AuthStore authStore,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y botón
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Citas Próximas',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Recargar citas al hacer clic en Ver Todo
                _loadUpcomingAppointments();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Citas actualizadas',
                      style: GoogleFonts.notoSans(),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'Ver Todo',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de citas
        _isLoadingAppointments
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            : _upcomingAppointments.isEmpty
                ? _buildEmptyAppointments(isDark)
                : Column(
                    children: _upcomingAppointments
                        .map((appointment) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppointmentCard(
                                appointment: appointment,
                                onTap: () => _showAppointmentDetails(appointment),
                              ),
                            ))
                        .toList(),
                  ),
      ],
    );
  }

  Widget _buildEmptyAppointments(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay citas programadas',
            style: GoogleFonts.notoSans(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona + para agregar una nueva cita',
            style: GoogleFonts.notoSans(
              color: isDark ? Colors.grey[600] : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Info de la cita
            _buildInfoRow(
              'Paciente',
              appointment.patientName,
              Icons.person,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Tratamiento',
              appointment.treatmentName,
              Icons.medical_services,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Fecha',
              _formatDate(appointment.appointmentDate),
              Icons.calendar_today,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Estado',
              appointment.status.displayName,
              Icons.flag,
              isDark,
            ),
            if (appointment.notes != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Notas',
                appointment.notes!,
                Icons.notes,
                isDark,
              ),
            ],
            const SizedBox(height: 24),
            
            // Acciones
            Text(
              'Cambiar estado:',
              style: GoogleFonts.notoSans(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppointmentStatus.values.map((status) {
                final isCurrentStatus = status == appointment.status;
                return FilterChip(
                  label: Text(
                    status.displayName,
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
                  selected: isCurrentStatus,
                  onSelected: isCurrentStatus 
                      ? null 
                      : (_) {
                          Navigator.pop(context);
                          _updateAppointmentStatus(appointment, status);
                        },
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
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClinicalEvaluationPage(
                        appointment: appointment,
                        patientName: appointment.patientName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment),
                label: Text(
                  'Iniciar Evaluación Clínica',
                  style: GoogleFonts.notoSans(),
                ),
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
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AiDiagnosisPage(
                        appointment: appointment,
                        patientName: appointment.patientName,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.auto_awesome, color: Colors.purple[400]),
                label: Text(
                  'Diagnosticar con IA',
                  style: GoogleFonts.notoSans(),
                ),
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
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAppointment(appointment);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  'Eliminar Cita',
                  style: GoogleFonts.notoSans(),
                ),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
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
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
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

  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Cita',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar esta cita? Esta acción no se puede deshacer.',
          style: GoogleFonts.notoSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.notoSans()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar', style: GoogleFonts.notoSans()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      await _appointmentsService.delete(
        appointment.appointmentId,
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cita eliminada exitosamente',
            style: GoogleFonts.notoSans(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadUpcomingAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.notoSans(),
          ),
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

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      await _appointmentsService.update(
        appointment.appointmentId,
        status: newStatus,
        token: token,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estado actualizado a: ${newStatus.displayName}',
            style: GoogleFonts.notoSans(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadUpcomingAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.notoSans(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
