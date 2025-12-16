import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/treatment_model.dart';
import '../../../core/providers/auth_store.dart';
import '../../../core/services/treatments_service.dart';
import '../../../core/services/patient_treatments_service.dart';
import '../../../theme/app_theme.dart';

class NewTreatmentPage extends StatefulWidget {
  final PatientModel patient;

  const NewTreatmentPage({
    super.key,
    required this.patient,
  });

  @override
  State<NewTreatmentPage> createState() => _NewTreatmentPageState();
}

class _NewTreatmentPageState extends State<NewTreatmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _notesController = TextEditingController();

  List<TreatmentModel> _treatments = [];
  TreatmentModel? _selectedTreatment;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isLoadingTreatments = false;

  @override
  void initState() {
    super.initState();
    _loadTreatments();
    // Establecer fecha de inicio por defecto como hoy
    _startDate = DateTime.now();
    _startDateController.text = DateFormat('MM/dd/yyyy').format(_startDate!);
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTreatments() async {
    setState(() => _isLoadingTreatments = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final treatments = await TreatmentsService.getTreatments(token);
      setState(() {
        _treatments = treatments;
        _isLoadingTreatments = false;
      });
    } catch (e) {
      setState(() => _isLoadingTreatments = false);
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: isStartDate ? DateTime.now() : (_startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: isDark ? AppTheme.cardDark : Colors.white,
              onSurface: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('MM/dd/yyyy').format(picked);
          // Si la fecha de fin ya está establecida y es anterior a la nueva fecha de inicio
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
            _endDateController.clear();
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('mm/dd/yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTreatment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tratamiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona las fechas de inicio y fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;
      final doctorId = authStore.currentUser?.id;

      if (token == null || doctorId == null) {
        throw Exception('No hay información de autenticación');
      }

      // Formatear fechas para el backend (YYYY-MM-DD)
      final startDate = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endDate = DateFormat('yyyy-MM-dd').format(_endDate!);

      await PatientTreatmentsService.createPatientTreatment(
        token: token,
        patientId: widget.patient.patientId,
        doctorId: doctorId,
        treatmentId: _selectedTreatment!.treatmentId,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tratamiento asignado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Regresar con resultado exitoso
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar tratamiento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authStore = context.watch<AuthStore>();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nueva Asignación',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card del Doctor
              _buildDoctorCard(isDark, authStore),
              const SizedBox(height: 16),

              // Card del Paciente
              _buildPatientCard(isDark),
              const SizedBox(height: 32),

              // Título de sección
              Text(
                'Detalles del Tratamiento',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Selector de tratamiento
              Text(
                'Tratamiento',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildTreatmentSelector(isDark),
              const SizedBox(height: 8),
              Text(
                'Seleccione el tratamiento principal de la base de datos.',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Fechas
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de Inicio',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _startDateController,
                          readOnly: true,
                          onTap: () => _selectDate(context, true),
                          style: GoogleFonts.notoSans(
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'mm/dd/yyyy',
                            hintStyle: GoogleFonts.notoSans(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary,
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary,
                              size: 20,
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de Fin',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _endDateController,
                          readOnly: true,
                          onTap: () => _selectDate(context, false),
                          style: GoogleFonts.notoSans(
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'mm/dd/yyyy',
                            hintStyle: GoogleFonts.notoSans(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary,
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary,
                              size: 20,
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notas clínicas / Dosis
              Text(
                'Notas Clínicas / Dosis',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: GoogleFonts.notoSans(
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Especifique dosis, frecuencia o instrucciones especiales...',
                  hintStyle: GoogleFonts.notoSans(
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
              const SizedBox(height: 40),

              // Botón de confirmar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Confirmar Asignación',
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(bool isDark, AuthStore authStore) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child: Text(
              authStore.initials,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authStore.doctorName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: #${authStore.currentUser?.id ?? 0}',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Espasticidad Grado 2',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF9D4EDD).withOpacity(0.2),
            child: Text(
              _getInitials(widget.patient.fullName),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9D4EDD),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.fullName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: SP-${widget.patient.patientId.toString().padLeft(3, '0')} • ${widget.patient.age} Años',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.medical_information,
                      size: 14,
                      color: const Color(0xFF9D4EDD),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Espasticidad Grado 2',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9D4EDD),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: _isLoadingTreatments
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<TreatmentModel>(
                value: _selectedTreatment,
                isExpanded: true,
                hint: Text(
                  'Seleccionar del catálogo...',
                  style: GoogleFonts.notoSans(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondary,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondary,
                ),
                dropdownColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                style: GoogleFonts.notoSans(
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  fontSize: 15,
                ),
                items: _treatments.map((treatment) {
                  return DropdownMenuItem<TreatmentModel>(
                    value: treatment,
                    child: Text(treatment.treatmentName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTreatment = value);
                },
              ),
            ),
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
