import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/patient_treatment_model.dart';
import '../../../theme/app_theme.dart';

class TreatmentCard extends StatelessWidget {
  final PatientTreatmentModel treatment;
  final VoidCallback? onTap;

  const TreatmentCard({
    super.key,
    required this.treatment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final treatmentName = treatment.treatment?.treatmentName ?? 'Tratamiento';
    
    // Calcular días de tratamiento
    final startDate = DateTime.parse(treatment.startDate);
    final endDate = DateTime.parse(treatment.endDate);
    final today = DateTime.now();
    final totalDays = endDate.difference(startDate).inDays;
    final daysPassed = today.difference(startDate).inDays;
    final progress = (daysPassed / totalDays).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
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
              // Header con ícono y estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          treatmentName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateRange(startDate, endDate),
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Activo',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barra de progreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adherencia: ${(progress * 100).toInt()}%',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'Próxima dosis: ${_getNextDoseTime()}',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]}, ${end.year}';
  }

  String _getNextDoseTime() {
    // Ejemplo simple - en producción calcular según horario real
    final now = DateTime.now();
    if (now.hour < 14) {
      return '2:00 PM';
    } else if (now.hour < 20) {
      return '8:00 PM';
    } else {
      return 'Mañana 8:00 AM';
    }
  }
}
