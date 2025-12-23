import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_store.dart';
import '../../../theme/app_theme.dart';
import '../../../screens/login_screen.dart';

/// Página de perfil del usuario
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final authStore = context.read<AuthStore>();
    final user = authStore.currentUser;
    if (user != null) {
      _fullNameController.text = user.fullName ?? user.username;
      _emailController.text = user.email;
      _fullNameController.addListener(_onFieldChanged);
      _emailController.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authStore.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No hay usuario',
            style: GoogleFonts.notoSans(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Avatar y nombre
                    _buildProfileHeader(authStore, user, isDark),
                    const SizedBox(height: 32),
                    // Información Personal
                    _buildPersonalInfoSection(isDark),
                    const SizedBox(height: 24),
                    // Actividad del Sistema
                    _buildSystemActivitySection(context, isDark),
                    const SizedBox(height: 24),
                    // Cuenta y Seguridad
                    _buildAccountSecuritySection(context, isDark),
                    const SizedBox(height: 32),
                    // Footer
                    _buildFooter(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Botón flotante inferior
      bottomNavigationBar: _buildSaveButton(context, isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.cardDark : AppTheme.cardLight).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón atrás
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Atrás',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Título centrado
          Expanded(
            child: Center(
              child: Text(
                'Mi Perfil',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          // Espacio para balancear
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthStore authStore, user, bool isDark) {
    return Column(
      children: [
        // Avatar con botón de editar
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: AppTheme.primary,
                child: Text(
                  authStore.initials,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Nombre
        Text(
          user.fullName ?? user.username,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        // Especialidad y Licencia
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.roleTier.toUpperCase(),
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Lic. #${user.id.toString().padLeft(6, '0')}',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMACIÓN PERSONAL',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                // Nombre Completo
                _buildEditableField(
                  icon: Icons.badge,
                  label: 'Nombre Completo',
                  controller: _fullNameController,
                  isDark: isDark,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                // Correo Electrónico
                _buildEditableField(
                  icon: Icons.mail,
                  label: 'Correo Electrónico',
                  controller: _emailController,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Estos datos se actualizarán en la tabla doctors.',
              style: GoogleFonts.notoSans(
                fontSize: 11,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemActivitySection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVIDAD DEL SISTEMA',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                _buildActivityButton(
                  context: context,
                  icon: Icons.history,
                  iconColor: const Color(0xFF9333EA),
                  title: 'Registro de Actividad',
                  subtitle: 'Ver system_logs recientes',
                  isDark: isDark,
                  onTap: () {
                    // TODO: Navegar a registro de actividad
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                _buildActivityButton(
                  context: context,
                  icon: Icons.analytics,
                  iconColor: const Color(0xFFEA580C),
                  title: 'Estadísticas de Diagnóstico',
                  isDark: isDark,
                  onTap: () {
                    // TODO: Navegar a estadísticas
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityButton({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDark ? 0.3 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSecuritySection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUENTA Y SEGURIDAD',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                // Cambiar Contraseña
                _buildSimpleButton(
                  title: 'Cambiar Contraseña',
                  isDark: isDark,
                  onTap: () {
                    // TODO: Navegar a cambiar contraseña
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                // Notificaciones Push
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notificaciones Push',
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                            _hasChanges = true;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                // Cerrar Sesión
                _buildSimpleButton(
                  title: 'Cerrar Sesión',
                  isDark: isDark,
                  textColor: Colors.red,
                  icon: Icons.logout,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleButton({
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    Color? textColor,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: textColor ?? (isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
              if (icon == null)
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            'NeuroResearch App v2.4.0 (Build 142)',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID de dispositivo: Flutter-${Theme.of(context).platform.name}',
            style: GoogleFonts.notoSans(
              fontSize: 10,
              color: isDark ? AppTheme.textTertiary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.cardDark : AppTheme.cardLight).withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _hasChanges ? () => _handleSave(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: AppTheme.primary.withOpacity(0.25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Guardar Cambios',
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSave(BuildContext context) {
    // TODO: Implementar guardado de cambios
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cambios guardados',
          style: GoogleFonts.notoSans(),
        ),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      _hasChanges = false;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cerrar Sesión',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: GoogleFonts.notoSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.notoSans(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.notoSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authStore = context.read<AuthStore>();
      await authStore.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
