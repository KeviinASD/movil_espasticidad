import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

/// Card de acción rápida reutilizable
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLarge;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isLarge = false,
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
          padding: EdgeInsets.all(isLarge ? 24 : 20),
          decoration: BoxDecoration(
            color: isLarge
                ? AppTheme.primary
                : (isDark ? AppTheme.cardDark : AppTheme.cardLight),
            borderRadius: BorderRadius.circular(16),
            border: isLarge
                ? null
                : Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 1,
                  ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLarge
                      ? Colors.white.withOpacity(0.2)
                      : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isLarge ? Colors.white : iconColor,
                  size: isLarge ? 28 : 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: isLarge ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: isLarge
                            ? Colors.white
                            : (isDark ? Colors.white : AppTheme.textPrimary),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: isLarge
                              ? Colors.white.withOpacity(0.8)
                              : (isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isLarge
                    ? Colors.white
                    : (isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondary),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
