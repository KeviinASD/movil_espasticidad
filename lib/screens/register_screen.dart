import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movil_espasticidad/screens/login_screen.dart';
import 'package:movil_espasticidad/services/auth_service.dart';
import 'package:movil_espasticidad/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _authService.register(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (token != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso. Inicia sesión.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Crear Cuenta',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 3 / 1,
                                    child: Image.network(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDkHRdnWLWagcnTv7DadhJlF155fNjHpDQS3taOO4hdM4twnksDM2cDckc3sgE8AG_lqQFwtJGdHhnHUeOJN08-zdScDzPqGPXznsElA_k9fItPyVt5OilradF1qKajEeyRgVNIQEJXAKcxu3lx2KCBN6TxdN2YMY3_csAFHVi5v3TkklEdHEcBA-dBsnxvFqDDiy5aDx7hIh28QHyklVYeti_dUqWgNbLUg01aBL4CFgFCMoOx-kjJEQU8npSv_QV_4K-dYmB8Sgvl',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: AppTheme.primary.withOpacity(0.1)),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primary.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  'Registro de Médico',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Únete a la red de investigación sobre espasticidad.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 16,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _LabeledField(
                                    label: 'Nombre Completo',
                                    icon: Icons.person_outline,
                                    controller: _fullNameController,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Ingrese su nombre completo' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    label: 'Correo Electrónico',
                                    icon: Icons.mail_outline,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Ingrese su correo electrónico';
                                      if (!v.contains('@')) return 'Correo inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    label: 'Usuario',
                                    icon: Icons.badge_outlined,
                                    controller: _usernameController,
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Ingrese un nombre de usuario' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    label: 'Contraseña',
                                    icon: Icons.lock_outline,
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Ingrese una contraseña';
                                      if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                                      return null;
                                    },
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    label: 'Confirmar Contraseña',
                                    icon: Icons.lock_reset_outlined,
                                    controller: _confirmPasswordController,
                                    obscureText: _obscurePassword,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Confirme su contraseña';
                                      if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.verified_user, size: 16, color: AppTheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Sus datos están protegidos y encriptados.',
                                        style: GoogleFonts.notoSans(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 8,
                                        shadowColor: AppTheme.primary.withOpacity(0.25),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Text('Registrarse'),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward, size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '¿Ya tienes una cuenta?',
                                        style: GoogleFonts.notoSans(
                                          fontSize: 14,
                                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const LoginScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Inicia Sesión',
                                          style: GoogleFonts.notoSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _LabeledField({
    required this.label,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: Icon(icon),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}