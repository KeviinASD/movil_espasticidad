import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/providers/auth_store.dart';
import '../../../core/services/patients_service.dart';
import '../../../theme/app_theme.dart';
import '../widgets/patient_card.dart';
import 'new_patient_page.dart';
import 'patient_detail_page.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  List<PatientModel> _patients = [];
  List<PatientModel> _filteredPatients = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';

  final List<String> _filters = [
    'Todos',
    'Espasticidad Leve',
    'Fase Estudio',
  ];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final patients = await PatientsService.getPatients(token);
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pacientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterPatients() {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        // Filtrar por búsqueda
        final matchesSearch = patient.fullName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());

        // TODO: Implementar filtros reales cuando el backend soporte estos campos
        // Por ahora, solo filtramos por búsqueda
        return matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterPatients();
  }

  void _onFilterSelected(String filter) {
    setState(() => _selectedFilter = filter);
    _filterPatients();
  }

  Future<void> _navigateToNewPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPatientPage()),
    );

    // Si se creó un paciente, recargar la lista
    if (result == true) {
      _loadPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),
            const SizedBox(height: 16),

            // Barra de búsqueda
            _buildSearchBar(isDark),
            const SizedBox(height: 16),

            // Filtros
            _buildFilters(isDark),
            const SizedBox(height: 16),

            // Contador de registros
            _buildCounter(isDark),
            const SizedBox(height: 12),

            // Lista de pacientes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPatients.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildPatientsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewPatient,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Lista de Pacientes',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        onChanged: _onSearchChanged,
        style: GoogleFonts.notoSans(
          color: isDark ? Colors.white : AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre...',
          hintStyle: GoogleFonts.notoSans(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
          suffixIcon: Icon(
            Icons.tune,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
          filled: true,
          fillColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) => _onFilterSelected(filter),
              labelStyle: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : AppTheme.textPrimary),
              ),
              backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              selectedColor: AppTheme.primary,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primary
                    : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCounter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'REGISTROS ACTIVOS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            '${_filteredPatients.length} pacientes asignados',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];

          // Generar datos de ejemplo para la UI (hasta que el backend los provea)
          final colors = [
            const Color(0xFF4CAF50), // Verde
            const Color(0xFFFFC107), // Amarillo
            const Color(0xFFF44336), // Rojo
            const Color(0xFF2196F3), // Azul
          ];

          final phases = ['FASE 1', 'FASE 2', 'FASE 3'];
          final statuses = [
            ('Estable', const Color(0xFF4CAF50)),
            ('Revisión', const Color(0xFFFFC107)),
            ('Evaluación', const Color(0xFFF44336)),
            ('Activo', const Color(0xFF4CAF50)),
            ('Finalizado', const Color(0xFF9E9E9E)),
          ];

          final sideBarColor = colors[index % colors.length];
          final phase = phases[index % phases.length];
          final statusInfo = statuses[index % statuses.length];

          return PatientCard(
            patient: patient,
            registrationNumber: '#RES-${patient.patientId.toString().padLeft(4, '0')}',
            phase: phase,
            status: statusInfo.$1,
            statusColor: statusInfo.$2,
            sideBarColor: sideBarColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailPage(patient: patient),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pacientes',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Agrega tu primer paciente'
                : 'No se encontraron resultados',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToNewPatient,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Paciente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
