import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/patient_model.dart';
import '../../../theme/app_theme.dart';

/// Card de paciente para la lista
class PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;
  final String registrationNumber;
  final String phase;
  final String status;
  final Color statusColor;
  final Color sideBarColor;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
    required this.registrationNumber,
    required this.phase,
    required this.status,
    required this.statusColor,
    required this.sideBarColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
              // Barra lateral de color
              Container(
                width: 4,
                height: 100,
                decoration: BoxDecoration(
                  color: sideBarColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Avatar o iniciales
              _buildAvatar(isDark),
              const SizedBox(width: 16),

              // Información del paciente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y número de registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            patient.fullName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          registrationNumber,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Fecha de nacimiento y edad
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatBirthDate(patient.birthDate)} (${patient.age} años)',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Fase y estado
                    Row(
                      children: [
                        // Fase
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            phase,
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Estado
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Ícono de flecha
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    // Extraer iniciales del nombre completo
    final names = patient.fullName.split(' ');
    String initials = '';
    if (names.isNotEmpty) {
      initials = names[0][0];
      if (names.length > 1) {
        initials += names[1][0];
      }
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: sideBarColor.withOpacity(0.2),
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: sideBarColor,
        ),
      ),
    );
  }

  String _formatBirthDate(String birthDate) {
    try {
      final date = DateTime.parse(birthDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return birthDate;
    }
  }
}
