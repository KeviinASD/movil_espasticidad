import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_store.dart';
import '../../../core/services/patients_service.dart';
import '../../../theme/app_theme.dart';

class NewPatientPage extends StatefulWidget {
  const NewPatientPage({super.key});

  @override
  State<NewPatientPage> createState() => _NewPatientPageState();
}

class _NewPatientPageState extends State<NewPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  
  bool _startTreatment = false;
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
        _selectedDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha de nacimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authStore = context.read<AuthStore>();
      final token = authStore.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Formatear fecha para el backend (YYYY-MM-DD)
      final birthDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      await PatientsService.createPatient(
        token: token,
        fullName: _fullNameController.text.trim(),
        birthDate: birthDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paciente ${_fullNameController.text} creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Regresar a la lista con resultado exitoso
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear paciente: $e'),
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
          icon: Icon(
            Icons.close,
            color: AppTheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nuevo Paciente',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de sección
                  Text(
                    'Datos personales',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingrese la información básica para registrar al paciente en el estudio de espasticidad.',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo: Nombre y Apellidos
                  Text(
                    'Nombre y Apellidos',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _fullNameController,
                    style: GoogleFonts.notoSans(
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej: Juan Pérez García',
                      hintStyle: GoogleFonts.notoSans(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Campo: Fecha de Nacimiento
                  Text(
                    'Fecha de Nacimiento',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    style: GoogleFonts.notoSans(
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'DD / MM / AAAA',
                      hintStyle: GoogleFonts.notoSans(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: AppTheme.primary,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La fecha de nacimiento es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  Divider(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                  const SizedBox(height: 24),

                  // Toggle: Iniciar tratamiento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Iniciar tratamiento',
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Comenzar el seguimiento tras guardar',
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _startTreatment,
                        onChanged: (value) {
                          setState(() => _startTreatment = value);
                        },
                        activeColor: AppTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),

                  // Footer con info del doctor
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.cardDark : AppTheme.cardLight).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Registrando como: ${authStore.doctorName}',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Guardar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePatient,
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
                                const Text(
                                  'Guardar Paciente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.check, size: 20),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
