import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/models/patient_treatment_model.dart';
import '../../../core/services/appointments_service.dart';
import '../../../core/services/patient_treatments_service.dart';
import '../../../core/providers/auth_store.dart';
import '../../../theme/app_theme.dart';

/// Pantalla para crear una nueva cita
class NewAppointmentPage extends StatefulWidget {
  final int? patientTreatmentId;
  final PatientTreatmentModel? treatment;

  const NewAppointmentPage({
    super.key,
    this.patientTreatmentId,
    this.treatment,
  });

  @override
  State<NewAppointmentPage> createState() => _NewAppointmentPageState();
}

class _NewAppointmentPageState extends State<NewAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentsService _appointmentsService = AppointmentsService();
  
  // Controladores
  final TextEditingController _notesController = TextEditingController();
  
  // Estado del formulario
  List<PatientTreatmentModel> _treatments = [];
  int? _selectedTreatmentId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  AppointmentStatus _selectedStatus = AppointmentStatus.scheduled;
  
  bool _isLoading = false;
  bool _isLoadingTreatments = true;

  @override
  void initState() {
    super.initState();
    _selectedTreatmentId = widget.patientTreatmentId;
    _loadTreatments();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTreatments() async {
    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;
      final doctorId = authStore.currentUser?.id;

      if (token == null) {
        setState(() => _isLoadingTreatments = false);
        return;
      }

      final treatments = await PatientTreatmentsService.getPatientTreatments(
        token: token,
        doctorId: doctorId,
      );

      if (!mounted) return;
      setState(() {
        _treatments = treatments;
        _isLoadingTreatments = false;
        
        // Si no hay tratamiento preseleccionado, usar el primero
        if (_selectedTreatmentId == null && treatments.isNotEmpty) {
          _selectedTreatmentId = treatments.first.patientTreatmentId;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingTreatments = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar tratamientos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTreatmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tratamiento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      // Combinar fecha y hora seleccionadas
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _appointmentsService.create(
        patientTreatmentId: _selectedTreatmentId!,
        appointmentDate: appointmentDateTime,
        status: _selectedStatus,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        token: token,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Retornar true para indicar éxito
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
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
    final authStore = context.watch<AuthStore>();
    final doctorName = authStore.doctorName;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),
            
            // Contenido
            Expanded(
              child: _isLoadingTreatments
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título de sección
                            _buildSectionTitle(isDark),
                            const SizedBox(height: 24),
                            
                            // Card de información general
                            _buildGeneralInfoCard(isDark, doctorName),
                            const SizedBox(height: 16),
                            
                            // Card de notas
                            _buildNotesCard(isDark),
                            const SizedBox(height: 24),
                            
                            // Botón crear
                            _buildCreateButton(isDark),
                            
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
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
              'Crear Nueva Cita',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Espacio para balancear
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge de investigación
        Row(
          children: [
            Icon(Icons.science, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              'INVESTIGACIÓN CLÍNICA',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Título
        Text(
          'Programar Cita',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        
        // Descripción
        Text(
          'Complete los datos para registrar una nueva sesión en el sistema.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoCard(bool isDark, String doctorName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
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
          // Header de la card
          Text(
            'INFORMACIÓN GENERAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          
          // Selector de tratamiento
          _buildLabel('Paciente y Tratamiento', isDark),
          const SizedBox(height: 8),
          _buildTreatmentDropdown(isDark),
          const SizedBox(height: 16),
          
          // Doctor asignado (solo lectura)
          _buildLabel('Especialista Asignado (Doctor)', isDark),
          const SizedBox(height: 8),
          _buildDoctorField(isDark, doctorName),
          const SizedBox(height: 16),
          
          // Fecha y hora
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Fecha', isDark),
                    const SizedBox(height: 8),
                    _buildDateField(isDark),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Hora', isDark),
                    const SizedBox(height: 8),
                    _buildTimeField(isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Estado inicial
          _buildLabel('Estado Inicial', isDark),
          const SizedBox(height: 8),
          _buildStatusDropdown(isDark),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTreatmentDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a232e) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedTreatmentId,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
          dropdownColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
          hint: Text(
            'Selecciona un tratamiento',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
          items: _treatments.map((treatment) {
            final patientName = treatment.patientName;
            final treatmentName = treatment.treatmentName;
            return DropdownMenuItem<int>(
              value: treatment.patientTreatmentId,
              child: Text(
                '$patientName - $treatmentName (Protocolo #SP-${treatment.patientTreatmentId})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedTreatmentId = value);
          },
        ),
      ),
    );
  }

  Widget _buildDoctorField(bool isDark, String doctorName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a232e) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            size: 20,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$doctorName (Tú)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a232e) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              _formatDate(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(bool isDark) {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a232e) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              _formatTime(_selectedTime),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    final statusOptions = [
      (AppointmentStatus.scheduled, 'Programada', Icons.event),
      (AppointmentStatus.inProgress, 'En Curso (Iniciar ahora)', Icons.play_circle),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a232e) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppointmentStatus>(
          value: _selectedStatus,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
          dropdownColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
          items: statusOptions.map((option) {
            return DropdownMenuItem<AppointmentStatus>(
              value: option.$1,
              child: Row(
                children: [
                  Icon(option.$3, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(option.$2),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedStatus = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildNotesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
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
          // Header
          Text(
            'NOTAS PRELIMINARES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          
          // Campo de texto
          Stack(
            children: [
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe instrucciones previas, recordatorios o contexto clínico para esta cita...',
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1a232e) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              // Botones de acciones
              Positioned(
                bottom: 8,
                right: 8,
                child: Row(
                  children: [
                    _buildNoteActionButton(Icons.mic, isDark),
                    const SizedBox(width: 4),
                    _buildNoteActionButton(Icons.attach_file, isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteActionButton(IconData icon, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Implementar funcionalidad
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función próximamente')),
          );
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppTheme.primary.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Crear y Programar Cita',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }
}

