import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home/pages/home_page.dart';
import '../patients/pages/patients_page.dart';
import '../research/pages/research_page.dart';
import '../profile/pages/profile_page.dart';

/// Pantalla principal con navegación inferior
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const PatientsPage(),
    const ResearchPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  label: 'Inicio',
                  index: 0,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.people,
                  label: 'Pacientes',
                  index: 1,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.search,
                  label: 'Investigar',
                  index: 2,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.person,
                  label: 'Perfil',
                  index: 3,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primary
                    : (isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondary),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primary
                      : (isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
