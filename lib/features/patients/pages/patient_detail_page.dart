import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/patient_treatment_model.dart';
import '../../../core/providers/auth_store.dart';
import '../../../core/services/patient_treatments_service.dart';
import '../../../theme/app_theme.dart';
import '../widgets/treatment_card.dart';
import 'new_treatment_page.dart';
import '../../appointments/pages/appointments_page.dart';

class PatientDetailPage extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailPage({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PatientTreatmentModel> _treatments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTreatments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTreatments() async {
    setState(() => _isLoading = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final treatments = await PatientTreatmentsService.getPatientTreatments(
        token: token,
        patientId: widget.patient.patientId,
        doctorId: authStore.currentUser?.id,
      );

      setState(() {
        _treatments = treatments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tratamientos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor:
                isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Detalle del Paciente',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Navegar a editar paciente
                },
              ),
            ],
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del paciente
                _buildPatientHeader(isDark),
                const SizedBox(height: 24),

                // Información adicional
                _buildPatientInfo(isDark),
                const SizedBox(height: 24),

                // Botones de acción
                _buildActionButtons(isDark),
                const SizedBox(height: 24),

                // Tabs
                _buildTabs(isDark),
              ],
            ),
          ),

          // Contenido de tabs
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResumenTab(isDark),
                _buildDiagnosticosTab(isDark),
                _buildCitasTab(isDark),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewTreatmentPage(patient: widget.patient),
            ),
          );

          // Si se agregó exitosamente, recargar tratamientos
          if (result == true) {
            _loadTreatments();
          }
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPatientHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Text(
                  _getInitials(widget.patient.fullName),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppTheme.backgroundDark
                          : AppTheme.backgroundLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.fullName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: #${widget.patient.patientId.toString().padLeft(4, '0')} • ${widget.patient.age} años',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Protocolo B',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Espasticidad Fase 3 • Ashworth: 3',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppTheme.primary.withOpacity(0.8),
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

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewTreatmentPage(patient: widget.patient),
                  ),
                );

                // Si se agregó exitosamente, recargar tratamientos
                if (result == true) {
                  _loadTreatments();
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo Tratamiento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Ver expediente
              },
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Ver Expediente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
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

  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor:
            isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
        indicatorColor: AppTheme.primary,
        labelStyle: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Resumen'),
          Tab(text: 'Diagnósticos'),
          Tab(text: 'Citas'),
        ],
      ),
    );
  }

  Widget _buildResumenTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadTreatments,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progreso de Citas
            _buildProgressSection(isDark),
            const SizedBox(height: 32),

            // Tratamientos Activos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tratamientos Activos',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Ver todos los tratamientos
                  },
                  child: Text(
                    'Ver Todo',
                    style: GoogleFonts.notoSans(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de tratamientos
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _treatments.isEmpty
                    ? _buildEmptyTreatments(isDark)
                    : Column(
                        children: _treatments
                            .map((treatment) => TreatmentCard(
                                  treatment: treatment,
                                  onTap: () {
                                    // Navegar a gestión de citas
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AppointmentsPage(
                                          patientTreatmentId: treatment.patientTreatmentId,
                                          treatment: treatment,
                                        ),
                                      ),
                                    );
                                  },
                                ))
                            .toList(),
                      ),
          ],
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
                'Progreso de Citas',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              Text(
                'Últimos 90 días',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '78%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: const Color(0xFF4CAF50),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+12%',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'vs. mes anterior',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Basado en tabla appointments',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color:
                  isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Gráfica
          SizedBox(
            height: 150,
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
                        const months = ['ENE', 'FEB', 'MAR', 'ABR'];
                        if (value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: GoogleFonts.notoSans(
                              fontSize: 10,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 4),
                      const FlSpot(2, 3.5),
                      const FlSpot(3, 5),
                    ],
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
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

  Widget _buildEmptyTreatments(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 60,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tratamientos activos',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega el primer tratamiento',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color:
                  isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticosTab(bool isDark) {
    return Center(
      child: Text(
        'Diagnósticos - Próximamente',
        style: GoogleFonts.notoSans(
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCitasTab(bool isDark) {
    if (_treatments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 60,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay tratamientos asignados',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega un tratamiento para ver las citas',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _treatments.length,
      itemBuilder: (context, index) {
        final treatment = _treatments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_note,
                color: AppTheme.primary,
              ),
            ),
            title: Text(
              treatment.treatmentName,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              'Ver citas del tratamiento',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentsPage(
                    patientTreatmentId: treatment.patientTreatmentId,
                    treatment: treatment,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    String initials = '';
    if (names.isNotEmpty) {
      initials = names[0][0];
      if (names.length > 1) {
        initials += names[1][0];
      }
    }
    return initials.toUpperCase();
  }
}
