import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/appointment_model.dart';
import '../../../theme/app_theme.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('hh:mm a');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
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
              // Avatar del paciente
              _buildAvatar(isDark),
              const SizedBox(width: 12),

              // Información de la cita
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y hora
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            appointment.patientName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.backgroundDark
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            timeFormat.format(appointment.appointmentDate),
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Tratamiento y estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tratamiento con punto de color
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getTreatmentColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appointment.treatmentName,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Badge de estado
                        _buildStatusBadge(isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    final patientName = appointment.patientName;
    final initials = _getInitials(patientName);

    // Por ahora usamos avatares con iniciales, podrías agregar imagen si el backend la provee
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getAvatarColor().withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _getAvatarColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    final status = appointment.status;
    Color bgColor;
    Color textColor;
    Color borderColor;
    String text;

    switch (status) {
      case AppointmentStatus.scheduled:
        bgColor = isDark
            ? const Color(0xFF3B82F6).withOpacity(0.2)
            : const Color(0xFFDCEEFF);
        textColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
        borderColor = isDark
            ? const Color(0xFF1E3A8A).withOpacity(0.5)
            : const Color(0xFF93C5FD);
        text = 'Confirmada';
        break;
      case AppointmentStatus.inProgress:
        bgColor = isDark
            ? const Color(0xFFF59E0B).withOpacity(0.2)
            : const Color(0xFFFEF3C7);
        textColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
        borderColor = isDark
            ? const Color(0xFF78350F).withOpacity(0.5)
            : const Color(0xFFFCD34D);
        text = 'En Sala';
        break;
      case AppointmentStatus.completed:
        bgColor = isDark
            ? const Color(0xFF10B981).withOpacity(0.2)
            : const Color(0xFFD1FAE5);
        textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
        borderColor = isDark
            ? const Color(0xFF064E3B).withOpacity(0.5)
            : const Color(0xFF6EE7B7);
        text = 'Completada';
        break;
      case AppointmentStatus.cancelled:
        bgColor = isDark
            ? const Color(0xFFEF4444).withOpacity(0.2)
            : const Color(0xFFFEE2E2);
        textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        borderColor = isDark
            ? const Color(0xFF7F1D1D).withOpacity(0.5)
            : const Color(0xFFFCA5A5);
        text = 'Cancelada';
        break;
      case AppointmentStatus.noShow:
        bgColor = isDark
            ? const Color(0xFF6B7280).withOpacity(0.2)
            : const Color(0xFFF3F4F6);
        textColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF374151);
        borderColor = isDark
            ? const Color(0xFF1F2937).withOpacity(0.5)
            : const Color(0xFF9CA3AF);
        text = 'No asistió';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
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

  Color _getAvatarColor() {
    // Genera un color basado en el nombre del paciente para consistencia
    final name = appointment.patientName;
    final hash = name.hashCode;
    final colors = [
      AppTheme.primary,
      const Color(0xFF9D4EDD),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getTreatmentColor() {
    // Genera un color basado en el tratamiento
    final treatment = appointment.treatmentName;
    final hash = treatment.hashCode;
    final colors = [
      const Color(0xFF3B82F6), // azul
      const Color(0xFFEF4444), // rojo
      const Color(0xFF10B981), // verde
      const Color(0xFFF59E0B), // amarillo
      const Color(0xFF9D4EDD), // morado
      const Color(0xFFEC4899), // rosa
    ];
    return colors[hash.abs() % colors.length];
  }
}
