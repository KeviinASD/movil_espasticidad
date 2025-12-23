import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/providers/auth_store.dart';

/// Página de analíticas con 3 secciones: KPIs, Preferencias IA, Diagnósticos
class ResearchPage extends StatefulWidget {
  const ResearchPage({super.key});

  @override
  State<ResearchPage> createState() => _ResearchPageState();
}

class _ResearchPageState extends State<ResearchPage> with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  TabController? _tabController;
  
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = '30d';
  
  // Datos para cada sección
  Map<String, dynamic>? _kpisData;
  Map<String, dynamic>? _aiPreferencesData;
  Map<String, dynamic>? _diagnosticsData;
  Map<String, dynamic>? _prevalenceData;
  List<Map<String, dynamic>> _recentDiagnostics = [];

  @override
  void initState() {
    super.initState();
    print('🚀 Inicializando ResearchPage...');
    _tabController = TabController(length: 3, vsync: this);
    print('✅ TabController inicializado');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
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

      if (token == null || token.isEmpty) {
        throw Exception('No hay token de autenticación. Por favor, inicia sesión.');
      }

      // Mapear período
      String? periodParam;
      if (_selectedPeriod == '7d') periodParam = '7d';
      else if (_selectedPeriod == '30d') periodParam = '30d';
      else if (_selectedPeriod == '1y') periodParam = '1y';

      // Cargar datos con manejo individual de errores
      final results = await Future.wait([
        _analyticsService.getKpis(period: periodParam, token: token).catchError((e) {
          print('⚠️ Error cargando KPIs: $e');
          return <String, dynamic>{'totalAppointments': 0, 'totalPatients': 0, 'successRate': 0};
        }),
        _analyticsService.getAiPreferences(period: periodParam, token: token).catchError((e) {
          print('⚠️ Error cargando preferencias IA: $e');
          return <String, dynamic>{
            'total': 0,
            'chatgptCount': 0,
            'copilotCount': 0,
            'chatgptPercentage': 0,
            'copilotPercentage': 0,
            'chatgptChange': 0,
            'weeklyTrend': <dynamic>[],
            'recentJustifications': <dynamic>[],
          };
        }),
        _analyticsService.getStatistics(period: periodParam, token: token).catchError((e) {
          print('⚠️ Error cargando estadísticas: $e');
          return <String, dynamic>{'totalDiagnoses': 0, 'totalAppointments': 0};
        }),
        _analyticsService.getPrevalence(token: token).catchError((e) {
          print('⚠️ Error cargando prevalencia: $e');
          return <String, dynamic>{
            'total': 0,
            'withSpasticity': 0,
            'withoutSpasticity': 0,
            'percentage': 0,
          };
        }),
        _analyticsService.getRecentEvaluations(limit: 10, token: token).catchError((e) {
          print('⚠️ Error cargando evaluaciones recientes: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      if (!mounted) return;

      print('✅ Datos cargados exitosamente');
      print('  KPIs: ${results[0]}');
      print('  AI Preferences: ${results[1]}');
      print('  AI Preferences tipo: ${results[1].runtimeType}');
      print('  Statistics: ${results[2]}');
      
      // Verificar específicamente los datos de AI Preferences
      final aiPrefs = results[1] as Map<String, dynamic>;
      print('  AI Preferences keys: ${aiPrefs.keys.toList()}');
      print('  AI Preferences total: ${aiPrefs['total']}');
      print('  AI Preferences weeklyTrend: ${aiPrefs['weeklyTrend']}');

      setState(() {
        _kpisData = results[0] as Map<String, dynamic>;
        _aiPreferencesData = results[1] as Map<String, dynamic>;
        _diagnosticsData = results[2] as Map<String, dynamic>;
        _prevalenceData = results[3] as Map<String, dynamic>;
        _recentDiagnostics = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
      
      print('✅ Estado actualizado, isLoading: false');
    } catch (e) {
      print('❌ Error general en _loadData: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildPeriodSelector(isDark),
            if (_tabController != null) _buildTabBar(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorWidget()
                      : _tabController != null
                          ? TabBarView(
                              controller: _tabController!,
                              children: [
                                _buildKpisTab(isDark),
                                _buildAiPreferencesTab(isDark),
                                _buildDiagnosticsTab(isDark),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
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
                  'Inicio',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Analíticas',
              style: GoogleFonts.notoSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.calendar_month,
              color: const Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildPeriodButton('7 Días', '7d', isDark),
            ),
            Expanded(
              child: _buildPeriodButton('30 Días', '30d', isDark),
            ),
            Expanded(
              child: _buildPeriodButton('1 Año', '1y', isDark),
            ),
            Expanded(
              child: _buildPeriodButton('Total', 'all', isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? Colors.grey[700] : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: GestureDetector(
        onTap: () => _onPeriodChanged(period),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey[400] : Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!.withOpacity(0.5),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController!,
        indicatorColor: AppTheme.primary,
        labelColor: AppTheme.primary,
        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
        labelStyle: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'KPIs'),
          Tab(text: 'Preferencias IA'),
          Tab(text: 'Diagnósticos'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar analíticas',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== TAB KPIs ==============
  Widget _buildKpisTab(bool isDark) {
    if (_kpisData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalAppointments = _kpisData!['totalAppointments'] ?? 0;
    final totalPatients = _kpisData!['totalPatients'] ?? 0;
    final successRate = _kpisData!['successRate'] ?? 0;
    final avgRecoveryTime = _kpisData!['avgRecoveryTime'] ?? 0.0;
    final appointmentsChange = _kpisData!['appointmentsChange'] ?? 0;
    final patientsChange = _kpisData!['patientsChange'] ?? 0;
    final appointmentsWeeklyEvolution = _kpisData!['appointmentsWeeklyEvolution'] as List<dynamic>? ?? [];
    final spasticityResponse = _kpisData!['spasticityResponse'] as Map<String, dynamic>? ?? {};
    final recentTreatments = _kpisData!['recentTreatments'] as List<dynamic>? ?? [];

    // Formatear cambios porcentuales
    String formatChange(int change) {
      if (change > 0) return '+$change%';
      if (change < 0) return '$change%';
      return '0%';
    }

    Color getChangeColor(int change) {
      if (change > 0) return const Color(0xFF0bda5b);
      if (change < 0) return const Color(0xFFfa6238);
      return Colors.grey;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid de KPIs
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildKpiCard(
                icon: Icons.calendar_month,
                value: totalAppointments.toString(),
                label: 'Citas Totales',
                change: formatChange(appointmentsChange),
                changeColor: getChangeColor(appointmentsChange),
                isDark: isDark,
              ),
              _buildKpiCard(
                icon: Icons.check_circle,
                value: '$successRate%',
                label: 'Éxito Tx',
                change: '', // No tenemos cambio histórico para éxito
                changeColor: const Color(0xFF0bda5b),
                isDark: isDark,
              ),
              _buildKpiCard(
                icon: Icons.people,
                value: totalPatients.toString(),
                label: 'Pacientes',
                change: formatChange(patientsChange),
                changeColor: getChangeColor(patientsChange),
                isDark: isDark,
              ),
              _buildKpiCard(
                icon: Icons.timer,
                value: avgRecoveryTime.toStringAsFixed(1),
                unit: 'sem',
                label: 'T. Recup.',
                change: '', // No tenemos cambio para tiempo de recuperación
                changeColor: const Color(0xFF0bda5b),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gráfico de evolución de citas
          _buildAppointmentsChart(isDark, appointmentsWeeklyEvolution),
          const SizedBox(height: 24),
          // Gráfico de respuesta a espasticidad
          _buildSpasticityResponseChart(isDark, spasticityResponse),
          const SizedBox(height: 24),
          // Últimos tratamientos
          _buildRecentTreatments(isDark, recentTreatments),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String value,
    String? unit,
    required String label,
    required String change,
    required Color changeColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C252E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      change.startsWith('+') ? Icons.trending_up : Icons.arrow_downward,
                      size: 12,
                      color: changeColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsChart(bool isDark, List<dynamic> weeklyEvolution) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C252E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolución de Citas',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Volumen semanal de consultas',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+12%',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gráfico simplificado (línea)
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _LineChartPainter(data: weeklyEvolution),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Sem 1', style: GoogleFonts.notoSans(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              Text('Sem 2', style: GoogleFonts.notoSans(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              Text('Sem 3', style: GoogleFonts.notoSans(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              Text('Sem 4', style: GoogleFonts.notoSans(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpasticityResponseChart(bool isDark, Map<String, dynamic> spasticityResponse) {
    final mejora = spasticityResponse['mejora'] ?? 65;
    final estable = spasticityResponse['estable'] ?? 25;
    final regresion = spasticityResponse['regresion'] ?? 10;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C252E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respuesta a Espasticidad',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Distribución por estado del paciente',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResponseBar('Mejora', mejora as int, const Color(0xFF0bda5b), isDark),
              _buildResponseBar('Estable', estable as int, AppTheme.primary, isDark),
              _buildResponseBar('Regresión', regresion as int, const Color(0xFFfa6238), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponseBar(String label, int percentage, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          '$percentage%',
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 120,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 40,
              height: (percentage / 100) * 120,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTreatments(bool isDark, List<dynamic> recentTreatments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Últimos Tratamientos',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Ver todo',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Lista de tratamientos desde backend
        if (recentTreatments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C252E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No hay tratamientos recientes',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ...recentTreatments.asMap().entries.map((entry) {
            final treatment = entry.value as Map<String, dynamic>;
            final index = entry.key;
            final treatmentName = treatment['treatmentName'] as String? ?? 'Tratamiento';
            final patientId = treatment['patientId'] as int? ?? 0;
            final status = treatment['status'] as String? ?? 'Pendiente';
            final timeAgo = treatment['timeAgo'] as String? ?? 'Reciente';
            
            // Mapear nombre de tratamiento a ícono
            IconData icon;
            if (treatmentName.toLowerCase().contains('toxina') || treatmentName.toLowerCase().contains('botulínica')) {
              icon = Icons.vaccines;
            } else if (treatmentName.toLowerCase().contains('fisioterapia')) {
              icon = Icons.fitness_center;
            } else {
              icon = Icons.medical_services;
            }
            
            // Mapear estado a color
            Color statusColor;
            if (status == 'COMPLETED' || status == 'Completado') {
              statusColor = AppTheme.primary;
            } else if (status.toLowerCase().contains('mejora')) {
              statusColor = const Color(0xFF0bda5b);
            } else {
              statusColor = Colors.grey;
            }
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < recentTreatments.length - 1 ? 12 : 0),
              child: _buildTreatmentItem(
                icon: icon,
                title: treatmentName,
                patientId: '#$patientId',
                status: status,
                statusColor: statusColor,
                timeAgo: timeAgo,
                isDark: isDark,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTreatmentItem({
    required IconData icon,
    required String title,
    required String patientId,
    required String status,
    required Color statusColor,
    required String timeAgo,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C252E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Paciente ID: $patientId',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeAgo,
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============== TAB PREFERENCIAS IA ==============
  Widget _buildAiPreferencesTab(bool isDark) {
    if (_aiPreferencesData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando preferencias IA...',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    try {
      final total = _aiPreferencesData!['total'] ?? 0;
      final chatgptCount = _aiPreferencesData!['chatgptCount'] ?? 0;
      final copilotCount = _aiPreferencesData!['copilotCount'] ?? 0;
      final chatgptPercentage = _aiPreferencesData!['chatgptPercentage'] ?? 0;
      final copilotPercentage = _aiPreferencesData!['copilotPercentage'] ?? 0;
      final chatgptChange = _aiPreferencesData!['chatgptChange'] as int? ?? 0;
      final weeklyTrend = _aiPreferencesData!['weeklyTrend'] as List<dynamic>? ?? [];
      final recentJustifications = _aiPreferencesData!['recentJustifications'] as List<dynamic>? ?? [];

      // Debug: imprimir datos para verificar
      print('📊 AI Preferences Data:');
      print('  total: $total');
      print('  chatgptCount: $chatgptCount');
      print('  copilotCount: $copilotCount');
      print('  chatgptPercentage: $chatgptPercentage');
      print('  copilotPercentage: $copilotPercentage');
      print('  chatgptChange: $chatgptChange');
      print('  weeklyTrend length: ${weeklyTrend.length}');
      print('  recentJustifications length: ${recentJustifications.length}');
      print('  _aiPreferencesData completo: $_aiPreferencesData');

    // Si no hay datos, mostrar mensaje
    if (total == 0 && chatgptCount == 0 && copilotCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.blue[300]),
              const SizedBox(height: 16),
              Text(
                'No hay datos de preferencias IA',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No se han registrado evaluaciones de IA seleccionadas aún.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta principal de líder
          _buildLeaderCard(
            context: context,
            chatgptPercentage: chatgptPercentage,
            copilotPercentage: copilotPercentage,
            chatgptCount: chatgptCount,
            copilotCount: copilotCount,
            chatgptChange: chatgptChange,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Grid de estadísticas secundarias
          Row(
            children: [
              Expanded(
                child: _buildSecondaryStatCard(
                  icon: Icons.analytics,
                  value: total.toString(),
                  label: 'Total Evaluaciones',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryStatCard(
                  icon: Icons.medical_services,
                  value: '4.8/5', // Mantener este valor por ahora, no está en el backend
                  label: 'Calidad Respuesta',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gráfico de tendencia semanal
          _buildWeeklyTrendChart(isDark),
          const SizedBox(height: 24),
          // Nube de motivos (mantener hardcoded por ahora, no está en el backend)
          _buildJustificationKeywords(isDark),
          const SizedBox(height: 24),
          // Justificaciones recientes
          _buildRecentJustifications(recentJustifications, isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
    } catch (e, stackTrace) {
      print('❌ Error construyendo tab de Preferencias IA: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error al mostrar preferencias IA',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLeaderCard({
    required BuildContext context,
    required int chatgptPercentage,
    required int copilotPercentage,
    required int chatgptCount,
    required int copilotCount,
    required int chatgptChange,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1b2631) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Líder Actual',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chatgptChange > 0
                      ? const Color(0xFF0bda5b).withOpacity(0.1)
                      : chatgptChange < 0
                          ? const Color(0xFFfa6238).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chatgptChange != 0
                      ? '${chatgptChange > 0 ? '+' : ''}$chatgptChange% vs período anterior'
                      : 'Sin cambios',
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: chatgptChange > 0
                        ? const Color(0xFF0bda5b)
                        : chatgptChange < 0
                            ? const Color(0xFFfa6238)
                            : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$chatgptPercentage%',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.smart_toy, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'ChatGPT',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$copilotPercentage%',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Copilot',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFa855f7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.code, size: 16, color: const Color(0xFFa855f7)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de comparación
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalPercentage = chatgptPercentage + copilotPercentage;
                final chatgptWidth = totalPercentage > 0 
                    ? (chatgptPercentage / totalPercentage) * constraints.maxWidth
                    : 0.0;
                final copilotWidth = totalPercentage > 0
                    ? (copilotPercentage / totalPercentage) * constraints.maxWidth
                    : 0.0;
                
                return Stack(
                  children: [
                    Row(
                      children: [
                        if (chatgptWidth > 0)
                          Container(
                            width: chatgptWidth,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: copilotWidth > 0
                                  ? const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    )
                                  : BorderRadius.circular(8),
                            ),
                          ),
                        if (copilotWidth > 0)
                          Container(
                            width: copilotWidth,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFa855f7),
                              borderRadius: chatgptWidth > 0
                                  ? const BorderRadius.only(
                                      topRight: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    )
                                  : BorderRadius.circular(8),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$chatgptCount Evaluaciones',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                '$copilotCount Evaluaciones',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStatCard({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1b2631) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendChart(bool isDark) {
    final weeklyTrend = _aiPreferencesData?['weeklyTrend'] as List<dynamic>? ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1b2631) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tendencia Semanal',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          if (weeklyTrend.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay datos disponibles',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gráfico de líneas
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _LineTrendChartPainter(
                      weeklyTrend: weeklyTrend,
                      isDark: isDark,
                    ),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 16),
                // Leyenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLineLegendItem(isDark, AppTheme.primary, 'ChatGPT'),
                    const SizedBox(width: 24),
                    _buildLineLegendItem(isDark, const Color(0xFFa855f7), 'Copilot'),
                  ],
                ),
                const SizedBox(height: 12),
                // Etiquetas de semanas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weeklyTrend.asMap().entries.map((entry) {
                    final index = entry.key;
                    final isCurrent = index == weeklyTrend.length - 1;
                    return Text(
                      isCurrent ? 'Actual' : 'Sem ${index + 1}',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? AppTheme.primary
                            : (isDark ? Colors.grey[500] : Colors.grey[500]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLineLegendItem(bool isDark, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }


  Widget _buildJustificationKeywords(bool isDark) {
    final keywords = [
      {'text': 'Precisión Clínica', 'percentage': '45%'},
      {'text': 'Velocidad', 'percentage': '22%'},
      {'text': 'Detalle en Dosis', 'percentage': '18%'},
      {'text': 'Lenguaje Natural', 'percentage': '10%'},
      {'text': 'Otros', 'percentage': '5%'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motivos de Elección',
          style: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.map((keyword) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.transparent,
                ),
              ),
              child: Text(
                '${keyword['text']} (${keyword['percentage']})',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentJustifications(List<dynamic> justifications, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Justificaciones Recientes',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Ver todas',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (justifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1b2631) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Center(
              child: Text(
                'No hay justificaciones recientes',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ...justifications.take(3).map((justification) {
            final toolName = justification['toolName'] as String? ?? 'IA';
            final isChatgpt = toolName.toLowerCase().contains('chatgpt') || toolName.toLowerCase().contains('gpt');
            final color = isChatgpt ? AppTheme.primary : const Color(0xFFa855f7);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1b2631) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  justification['doctorName'] as String? ?? 'Dr. Usuario',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(justification['date']),
                                  style: GoogleFonts.notoSans(
                                    fontSize: 10,
                                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            toolName,
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          constraints: const BoxConstraints(minHeight: 40),
                        ),
                        Expanded(
                          child: Text(
                            justification['justification'] as String? ?? '',
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  // ============== TAB DIAGNÓSTICOS ==============
  Widget _buildDiagnosticsTab(bool isDark) {
    if (_diagnosticsData == null || _prevalenceData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando diagnósticos...'),
          ],
        ),
      );
    }

    final totalDiagnoses = _diagnosticsData!['totalDiagnoses'] ?? 0;
    final withSpasticity = _prevalenceData!['withSpasticity'] ?? 0;
    final withoutSpasticity = _prevalenceData!['withoutSpasticity'] ?? 0;
    final percentage = _prevalenceData!['percentage'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards Summary
          Row(
            children: [
              Expanded(
                child: _buildDiagnosticKpiCard(
                  icon: Icons.medical_services,
                  value: totalDiagnoses.toString(),
                  label: 'Total Diagnósticos',
                  change: _diagnosticsData?['diagnosesChange'] != null
                      ? '${(_diagnosticsData!['diagnosesChange'] as int) > 0 ? '+' : ''}${_diagnosticsData!['diagnosesChange']}%'
                      : null,
                  changeColor: _diagnosticsData?['diagnosesChange'] != null
                      ? ((_diagnosticsData!['diagnosesChange'] as int) > 0
                          ? const Color(0xFF0bda5b)
                          : const Color(0xFFfa6238))
                      : null,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDiagnosticKpiCard(
                  icon: Icons.check_circle,
                  value: withSpasticity.toString(),
                  label: 'Con Espasticidad',
                  percentage: percentage,
                  isPositive: true,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDiagnosticKpiCard(
                  icon: Icons.cancel,
                  value: withoutSpasticity.toString(),
                  label: 'Sin Espasticidad',
                  percentage: (100 - percentage).toInt(),
                  isPositive: false,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Donut Chart
          _buildDonutChart(percentage, withSpasticity, withoutSpasticity, isDark),
          const SizedBox(height: 24),
          // Bar Chart (Timeline)
          _buildMonthlyEvolutionChart(isDark, _diagnosticsData?['monthlyEvolution'] as List<dynamic>? ?? []),
          const SizedBox(height: 24),
          // Recent Diagnostics List
          _buildRecentDiagnosticsList(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDiagnosticKpiCard({
    required IconData icon,
    required String value,
    required String label,
    String? change,
    Color? changeColor,
    int? percentage,
    bool? isPositive,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              if (change != null && changeColor != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 12,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        change,
                        style: GoogleFonts.notoSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (percentage != null && isPositive != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: isPositive ? AppTheme.primary : Colors.grey[400],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$percentage%',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPositive ? AppTheme.primary : Colors.grey[400],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonutChart(int percentage, int withSpasticity, int withoutSpasticity, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de Casos',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Leyenda
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Positivos', percentage, AppTheme.primary, isDark),
                    const SizedBox(height: 16),
                    _buildLegendItem('Negativos', 100 - percentage, Colors.grey[400]!, isDark),
                  ],
                ),
              ),
              // Donut Chart
              SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 128,
                      height: 128,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 16,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    ),
                    Icon(
                      Icons.pie_chart,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            '$value%',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyEvolutionChart(bool isDark, List<dynamic> monthlyEvolution) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2630) : Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evolución Mensual',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver Todo',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (monthlyEvolution.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay datos disponibles',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gráfico de líneas
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _MonthlyEvolutionChartPainter(
                      monthlyEvolution: monthlyEvolution,
                      isDark: isDark,
                    ),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 16),
                // Leyenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMonthlyLegendItem(isDark, AppTheme.primary, 'Espasticidad'),
                    const SizedBox(width: 24),
                    _buildMonthlyLegendItem(isDark, Colors.grey[400]!, 'Sin Espasticidad'),
                  ],
                ),
                const SizedBox(height: 12),
                // Etiquetas de meses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: monthlyEvolution.asMap().entries.map((entry) {
                    final index = entry.key;
                    final isCurrent = index == monthlyEvolution.length - 1;
                    return Text(
                      isCurrent ? 'Actual' : 'Mes ${index + 1}',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? AppTheme.primary
                            : (isDark ? Colors.grey[500] : Colors.grey[500]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyLegendItem(bool isDark, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDiagnosticsList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diagnósticos Recientes',
          style: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (_recentDiagnostics.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1c2630) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Center(
              child: Text(
                'No hay diagnósticos recientes',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ..._recentDiagnostics.take(3).map((diagnostic) {
            final hasSpasticity = diagnostic['hasSpasticity'] == true;
            final patientName = diagnostic['patientName'] as String? ?? 'Paciente';
            final diagnosisDate = diagnostic['diagnosisDate'] != null
                ? DateTime.tryParse(diagnostic['diagnosisDate'].toString())
                : null;
            final timeAgo = _getTimeAgo(diagnosisDate);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1c2630) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        color: isDark ? Colors.grey[400] : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasSpasticity
                            ? AppTheme.primary.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasSpasticity
                              ? AppTheme.primary.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        hasSpasticity ? 'Detectado' : 'Negativo',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasSpasticity ? AppTheme.primary : Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  String _getTimeAgo(dynamic date) {
    if (date == null) return 'Reciente';
    
    DateTime? dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date);
    } else if (date is DateTime) {
      dateTime = date;
    }
    
    if (dateTime == null) return 'Reciente';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }
}

// Custom painter para el gráfico de línea de tendencia semanal
class _LineTrendChartPainter extends CustomPainter {
  final List<dynamic> weeklyTrend;
  final bool isDark;

  _LineTrendChartPainter({
    required this.weeklyTrend,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyTrend.isEmpty) return;

    final chatgptValues = weeklyTrend.map((w) => (w as Map<String, dynamic>)['chatgpt'] as int? ?? 0).toList();
    final copilotValues = weeklyTrend.map((w) => (w as Map<String, dynamic>)['copilot'] as int? ?? 0).toList();

    const double padding = 20.0;
    final double chartWidth = size.width - (padding * 2);
    final double chartHeight = size.height - (padding * 2);
    final double stepX = weeklyTrend.length > 1 ? chartWidth / (weeklyTrend.length - 1) : 0;

    // Dibujar líneas de referencia (grid)
    final gridPaint = Paint()
      ..color = isDark ? Colors.grey[800]! : Colors.grey[200]!
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Función para convertir valor a coordenada Y
    double valueToY(int value) {
      return padding + chartHeight - (value / 100) * chartHeight;
    }

    // Dibujar línea de Copilot (fondo)
    if (copilotValues.any((v) => v > 0)) {
      final copilotPath = Path();
      final copilotPaint = Paint()
        ..color = const Color(0xFFa855f7)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < copilotValues.length; i++) {
        final x = padding + (stepX * i);
        final y = valueToY(copilotValues[i]);
        if (i == 0) {
          copilotPath.moveTo(x, y);
        } else {
          copilotPath.lineTo(x, y);
        }
      }
      canvas.drawPath(copilotPath, copilotPaint);

      // Dibujar puntos de Copilot
      final copilotPointPaint = Paint()
        ..color = const Color(0xFFa855f7)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < copilotValues.length; i++) {
        final x = padding + (stepX * i);
        final y = valueToY(copilotValues[i]);
        canvas.drawCircle(Offset(x, y), 5, copilotPointPaint);
        // Dibujar valor
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${copilotValues[i]}%',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 18));
      }
    }

    // Dibujar línea de ChatGPT
    if (chatgptValues.any((v) => v > 0)) {
      final chatgptPath = Path();
      final chatgptPaint = Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < chatgptValues.length; i++) {
        final x = padding + (stepX * i);
        final y = valueToY(chatgptValues[i]);
        if (i == 0) {
          chatgptPath.moveTo(x, y);
        } else {
          chatgptPath.lineTo(x, y);
        }
      }
      canvas.drawPath(chatgptPath, chatgptPaint);

      // Dibujar puntos de ChatGPT
      final chatgptPointPaint = Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.fill;
      for (int i = 0; i < chatgptValues.length; i++) {
        final x = padding + (stepX * i);
        final y = valueToY(chatgptValues[i]);
        canvas.drawCircle(Offset(x, y), 5, chatgptPointPaint);
        // Dibujar valor
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${chatgptValues[i]}%',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineTrendChartPainter oldDelegate) =>
      oldDelegate.weeklyTrend != weeklyTrend || oldDelegate.isDark != isDark;
}

// Custom painter para el gráfico de línea de evolución mensual
class _MonthlyEvolutionChartPainter extends CustomPainter {
  final List<dynamic> monthlyEvolution;
  final bool isDark;

  _MonthlyEvolutionChartPainter({
    required this.monthlyEvolution,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyEvolution.isEmpty) return;

    final withSpasticityValues = monthlyEvolution.map((m) => (m as Map<String, dynamic>)['withSpasticity'] as int? ?? 0).toList();
    final withoutSpasticityValues = monthlyEvolution.map((m) => (m as Map<String, dynamic>)['withoutSpasticity'] as int? ?? 0).toList();

    const double padding = 20.0;
    final double chartWidth = size.width - (padding * 2);
    final double chartHeight = size.height - (padding * 2);
    final double stepX = monthlyEvolution.length > 1 ? chartWidth / (monthlyEvolution.length - 1) : 0;

    // Dibujar líneas de referencia (grid)
    final gridPaint = Paint()
      ..color = isDark ? Colors.grey[800]! : Colors.grey[200]!
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Función para convertir porcentaje a coordenada Y (los valores ya vienen como porcentajes 0-100)
    double valueToY(int percentage) {
      return padding + chartHeight - (percentage / 100) * chartHeight;
    }

    // Dibujar línea de Sin Espasticidad (fondo)
    if (withoutSpasticityValues.any((v) => v > 0)) {
      final withoutPath = Path();
      final withoutPaint = Paint()
        ..color = Colors.grey[400]!
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < withoutSpasticityValues.length; i++) {
        final x = padding + (stepX * i);
        final y = valueToY(withoutSpasticityValues[i]);
        if (i == 0) {
          withoutPath.moveTo(x, y);
        } else {
          withoutPath.lineTo(x, y);
        }
      }
      canvas.drawPath(withoutPath, withoutPaint);

      // Dibujar puntos de Sin Espasticidad
      final withoutPointPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.fill;
      for (int i = 0; i < withoutSpasticityValues.length; i++) {
        final x = padding + (stepX * i);
        final y = valueToY(withoutSpasticityValues[i]);
        canvas.drawCircle(Offset(x, y), 5, withoutPointPaint);
        // Dibujar valor si es suficientemente grande
        if (withoutSpasticityValues[i] > 5) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${withoutSpasticityValues[i]}%',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 18));
        }
      }
    }

    // Dibujar línea de Con Espasticidad
    if (withSpasticityValues.any((v) => v > 0)) {
      final withPath = Path();
      final withPaint = Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < withSpasticityValues.length; i++) {
        final x = padding + (stepX * i);
        final y = valueToY(withSpasticityValues[i]);
        if (i == 0) {
          withPath.moveTo(x, y);
        } else {
          withPath.lineTo(x, y);
        }
      }
      canvas.drawPath(withPath, withPaint);

      // Dibujar puntos de Con Espasticidad
      final withPointPaint = Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.fill;
      for (int i = 0; i < withSpasticityValues.length; i++) {
        final x = padding + (stepX * i);
        final y = valueToY(withSpasticityValues[i]);
        canvas.drawCircle(Offset(x, y), 5, withPointPaint);
        // Dibujar valor si es suficientemente grande
        if (withSpasticityValues[i] > 5) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${withSpasticityValues[i]}%',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 18));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyEvolutionChartPainter oldDelegate) =>
      oldDelegate.monthlyEvolution != monthlyEvolution || oldDelegate.isDark != isDark;
}

// Custom painter para el gráfico de línea
class _LineChartPainter extends CustomPainter {
  final List<dynamic> data;

  _LineChartPainter({this.data = const []});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      // Si no hay datos, dibujar línea plana
      final paint = Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final normalizedData = data.map((v) => (v as num).toDouble()).toList();
    
    // Normalizar datos al rango de altura disponible (invertir porque Y crece hacia abajo)
    final maxValue = normalizedData.isEmpty ? 1 : normalizedData.reduce((a, b) => a > b ? a : b);
    final minValue = 0;
    final range = maxValue - minValue;
    
    final pointCount = normalizedData.length;
    final points = <Offset>[];
    
    for (int i = 0; i < pointCount; i++) {
      final x = size.width * (i + 1) / (pointCount + 1);
      final normalizedY = range > 0 
        ? (normalizedData[i] - minValue) / range 
        : 0.5;
      final y = size.height * (1 - normalizedY * 0.8 - 0.1); // Dejar 10% de margen arriba y abajo
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, paint);

      // Dibujar puntos
      final pointPaint = Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
      }

      // Relleno con gradiente
      final fillPath = Path.from(path);
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..color = AppTheme.primary.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => 
    oldDelegate.data != data;
}
