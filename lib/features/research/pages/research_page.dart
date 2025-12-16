import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

/// Página de investigación (placeholder)
class ResearchPage extends StatelessWidget {
  const ResearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        elevation: 0,
        title: Text(
          'Investigar',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 80,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Base de Datos de Ensayos',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
