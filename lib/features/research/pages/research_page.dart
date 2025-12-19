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
      print('  Statistics: ${results[2]}');

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
                change: '+12%',
                changeColor: const Color(0xFF0bda5b),
                isDark: isDark,
              ),
              _buildKpiCard(
                icon: Icons.check_circle,
                value: '$successRate%',
                label: 'Éxito Tx',
                change: '+2.5%',
                changeColor: const Color(0xFF0bda5b),
                isDark: isDark,
              ),
              _buildKpiCard(
                icon: Icons.people,
                value: totalPatients.toString(),
                label: 'Pacientes',
                change: '+4',
                changeColor: const Color(0xFF0bda5b),
                isDark: isDark,
              ),
              _buildKpiCard(
                icon: Icons.timer,
                value: '3.2',
                unit: 'sem',
                label: 'T. Recup.',
                change: '-1.2%',
                changeColor: const Color(0xFF0bda5b),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gráfico de evolución de citas
          _buildAppointmentsChart(isDark),
          const SizedBox(height: 24),
          // Gráfico de respuesta a espasticidad
          _buildSpasticityResponseChart(isDark),
          const SizedBox(height: 24),
          // Últimos tratamientos
          _buildRecentTreatments(isDark),
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

  Widget _buildAppointmentsChart(bool isDark) {
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
              painter: _LineChartPainter(),
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

  Widget _buildSpasticityResponseChart(bool isDark) {
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
              _buildResponseBar('Mejora', 65, const Color(0xFF0bda5b), isDark),
              _buildResponseBar('Estable', 25, AppTheme.primary, isDark),
              _buildResponseBar('Regresión', 10, const Color(0xFFfa6238), isDark),
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

  Widget _buildRecentTreatments(bool isDark) {
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
        // Lista de tratamientos (simplificada)
        _buildTreatmentItem(
          icon: Icons.vaccines,
          title: 'Toxina Botulínica',
          patientId: '#8291',
          status: 'Completado',
          statusColor: AppTheme.primary,
          timeAgo: 'Hace 2h',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTreatmentItem(
          icon: Icons.fitness_center,
          title: 'Fisioterapia',
          patientId: '#3312',
          status: 'Mejora',
          statusColor: const Color(0xFF0bda5b),
          timeAgo: 'Ayer',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTreatmentItem(
          icon: Icons.medical_services,
          title: 'Evaluación Inicial',
          patientId: '#9921',
          status: 'Pendiente',
          statusColor: Colors.grey,
          timeAgo: 'Ayer',
          isDark: isDark,
        ),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando preferencias IA...'),
          ],
        ),
      );
    }

    final total = _aiPreferencesData!['total'] ?? 0;
    final chatgptCount = _aiPreferencesData!['chatgptCount'] ?? 0;
    final copilotCount = _aiPreferencesData!['copilotCount'] ?? 0;
    final chatgptPercentage = _aiPreferencesData!['chatgptPercentage'] ?? 0;
    final copilotPercentage = _aiPreferencesData!['copilotPercentage'] ?? 0;
    final recentJustifications = _aiPreferencesData!['recentJustifications'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta principal de líder
          _buildLeaderCard(
            chatgptPercentage: chatgptPercentage,
            copilotPercentage: copilotPercentage,
            chatgptCount: chatgptCount,
            copilotCount: copilotCount,
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
                  value: '4.8/5',
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
          // Nube de motivos
          _buildJustificationKeywords(isDark),
          const SizedBox(height: 24),
          // Justificaciones recientes
          _buildRecentJustifications(recentJustifications, isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLeaderCard({
    required int chatgptPercentage,
    required int copilotPercentage,
    required int chatgptCount,
    required int copilotCount,
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
                  color: const Color(0xFF0bda5b).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+12% vs mes anterior',
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0bda5b),
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
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: chatgptPercentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: copilotPercentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFa855f7),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (chatgptPercentage > 0 && copilotPercentage > 0)
                  Positioned(
                    left: (chatgptPercentage / 100) * MediaQuery.of(context).size.width * 0.85,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                    ),
                  ),
              ],
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
          Text(
            'Tendencia Semanal',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildWeekBar(40, 30, 1, isDark),
                _buildWeekBar(55, 25, 2, isDark),
                _buildWeekBar(70, 45, 3, isDark),
                _buildWeekBar(65, 50, 4, isDark),
                _buildWeekBar(85, 40, 5, isDark, isCurrent: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ChatGPT',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFa855f7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Copilot',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBar(int chatgptHeight, int copilotHeight, int week, bool isDark, {bool isCurrent = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: 160,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Copilot (fondo)
              Positioned(
                bottom: 0,
                child: Container(
                  width: 16,
                  height: (copilotHeight / 100) * 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFa855f7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // ChatGPT (delante)
              Positioned(
                bottom: (copilotHeight / 100) * 160,
                child: Container(
                  width: 16,
                  height: (chatgptHeight / 100) * 160,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isCurrent ? 'Actual' : 'Sem $week',
          style: GoogleFonts.notoSans(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? (isDark ? Colors.grey[300] : Colors.grey[700])
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
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
                    Container(
                      width: 4,
                      height: double.infinity,
                      color: color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      justification['justification'] as String? ?? '',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.5,
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
                  change: '+12%',
                  changeColor: const Color(0xFF0bda5b),
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
          _buildMonthlyEvolutionChart(isDark),
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

  Widget _buildMonthlyEvolutionChart(bool isDark) {
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
          const SizedBox(height: 24),
          SizedBox(
            height: 192,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMonthBar(30, 45, 1, isDark),
                _buildMonthBar(25, 60, 2, isDark),
                _buildMonthBar(20, 75, 3, isDark, isCurrent: true),
                _buildMonthBar(35, 50, 4, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Espasticidad',
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sin Espasticidad',
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthBar(int withoutHeight, int withHeight, int week, bool isDark, {bool isCurrent = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: 192,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Sin espasticidad (fondo)
              Positioned(
                bottom: 0,
                child: Container(
                  width: 16,
                  height: (withoutHeight / 100) * 192,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              // Con espasticidad (arriba)
              Positioned(
                bottom: (withoutHeight / 100) * 192,
                child: Container(
                  width: 16,
                  height: (withHeight / 100) * 192,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isCurrent ? 'Sem 3' : 'Sem $week',
          style: GoogleFonts.notoSans(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
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

// Custom painter para el gráfico de línea
class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.4),
      Offset(size.width * 0.9, size.height * 0.2),
    ];

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
    fillPath.lineTo(size.width * 0.9, size.height);
    fillPath.lineTo(size.width * 0.1, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
