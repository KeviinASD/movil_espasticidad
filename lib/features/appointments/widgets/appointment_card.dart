import 'package:flutter/material.dart';
import '../../../core/models/appointment_model.dart';
import '../../../theme/app_theme.dart';

/// Tarjeta de cita siguiendo el diseño HTML proporcionado
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
    final config = _getStatusConfig(appointment.status);
    
    final isCancelled = appointment.status == AppointmentStatus.cancelled;
    final isCompleted = appointment.status == AppointmentStatus.completed;
    
    return Opacity(
      opacity: isCancelled ? 0.6 : (isCompleted ? 0.75 : 1.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: appointment.status == AppointmentStatus.inProgress
                    ? config.color.withOpacity(0.3)
                    : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
              ),
              boxShadow: appointment.status == AppointmentStatus.inProgress
                  ? [
                      BoxShadow(
                        color: config.color.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // Línea lateral de color
                if (appointment.status == AppointmentStatus.inProgress)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: config.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                
                // Contenido
                Padding(
                  padding: EdgeInsets.only(
                    left: appointment.status == AppointmentStatus.inProgress ? 8 : 0,
                  ),
                  child: Row(
                    children: [
                      // Ícono
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCancelled || isCompleted
                              ? (isDark ? Colors.grey[800] : Colors.grey[100])
                              : config.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          config.icon,
                          color: isCancelled 
                              ? Colors.grey[400]
                              : (isCompleted ? Colors.grey[500] : config.color),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título y badge de estado
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getAppointmentTitle(appointment),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppTheme.textPrimary,
                                      decoration: isCancelled 
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: Colors.grey[400],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(config, isDark),
                              ],
                            ),
                            const SizedBox(height: 4),
                            
                            // Fecha y hora
                            Row(
                              children: [
                                Icon(
                                  _getTimeIcon(appointment.status),
                                  size: 14,
                                  color: isDark 
                                      ? AppTheme.textSecondaryDark 
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(appointment),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark 
                                        ? AppTheme.textSecondaryDark 
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Chevron
                      Icon(
                        Icons.chevron_right,
                        color: isDark 
                            ? AppTheme.textSecondaryDark 
                            : AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(_StatusConfig config, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: config.color.withOpacity(0.2),
        ),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: config.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return _StatusConfig(
          color: Colors.green,
          backgroundColor: Colors.green.withOpacity(0.1),
          icon: Icons.event,
          label: 'PROGRAMADA',
        );
      case AppointmentStatus.inProgress:
        return _StatusConfig(
          color: Colors.blue,
          backgroundColor: Colors.blue.withOpacity(0.1),
          icon: Icons.accessibility_new,
          label: 'EN PROCESO',
        );
      case AppointmentStatus.completed:
        return _StatusConfig(
          color: Colors.grey,
          backgroundColor: Colors.grey.withOpacity(0.1),
          icon: Icons.check_circle,
          label: 'COMPLETADA',
        );
      case AppointmentStatus.cancelled:
        return _StatusConfig(
          color: Colors.red,
          backgroundColor: Colors.red.withOpacity(0.1),
          icon: Icons.cancel,
          label: 'CANCELADA',
        );
      case AppointmentStatus.noShow:
        return _StatusConfig(
          color: Colors.orange,
          backgroundColor: Colors.orange.withOpacity(0.1),
          icon: Icons.event_busy,
          label: 'NO ASISTIÓ',
        );
    }
  }

  IconData _getTimeIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.completed:
        return Icons.event_available;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.noShow:
        return Icons.event_busy;
      default:
        return Icons.schedule;
    }
  }

  String _getAppointmentTitle(AppointmentModel appointment) {
    // Si tiene notas, usarlas como título
    if (appointment.notes != null && appointment.notes!.isNotEmpty) {
      return appointment.notes!;
    }
    
    // Título por defecto basado en el estado
    switch (appointment.status) {
      case AppointmentStatus.inProgress:
        return 'Evaluación Motora';
      case AppointmentStatus.scheduled:
        return 'Sesión Programada';
      case AppointmentStatus.completed:
        return 'Consulta Completada';
      case AppointmentStatus.cancelled:
        return 'Cita Cancelada';
      case AppointmentStatus.noShow:
        return 'Paciente no asistió';
    }
  }

  String _formatDateTime(AppointmentModel appointment) {
    final date = appointment.appointmentDate;
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    if (appointment.status == AppointmentStatus.completed) {
      return '${date.day} ${months[date.month - 1]}, $hour12:$minute $period • Finalizado';
    }
    
    return '${date.day} ${months[date.month - 1]}, $hour12:$minute $period';
  }
}

class _StatusConfig {
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final String label;

  _StatusConfig({
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.label,
  });
}

