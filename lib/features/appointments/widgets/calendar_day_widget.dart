import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Widget para mostrar un día en el calendario horizontal
class CalendarDayWidget extends StatelessWidget {
  final String dayName;
  final int dayNumber;
  final bool isSelected;
  final bool isPast;
  final bool hasAppointment;
  final VoidCallback? onTap;

  const CalendarDayWidget({
    super.key,
    required this.dayName,
    required this.dayNumber,
    this.isSelected = false,
    this.isPast = false,
    this.hasAppointment = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primary
              : (isDark ? AppTheme.cardDark : AppTheme.cardLight),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: isPast && !isSelected ? 0.6 : 1.0,
          child: Transform.scale(
            scale: isSelected ? 1.05 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nombre del día
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white.withOpacity(0.8)
                        : (isDark 
                            ? AppTheme.textSecondaryDark 
                            : AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Número del día
                Text(
                  dayNumber.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppTheme.textPrimary),
                  ),
                ),
                
                // Indicador de cita
                if (hasAppointment || isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white 
                          : AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

