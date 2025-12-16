import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:movil_espasticidad/core/providers/auth_store.dart';
import 'package:movil_espasticidad/screens/splash_screen.dart';
import 'package:movil_espasticidad/screens/login_screen.dart';
import 'package:movil_espasticidad/features/main/main_screen.dart';
import 'package:movil_espasticidad/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar .env (si no existe, continuar con valores por defecto)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Ignorar si falta el archivo .env para evitar FileNotFoundError en web/debug
  }
  
  runApp(const FisioLabApp());
}

class FisioLabApp extends StatelessWidget {
  const FisioLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthStore()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'FisioLab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        locale: const Locale('es', 'ES'),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper para decidir qué pantalla mostrar según autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStore>(
      builder: (context, authStore, child) {
        // Mostrar splash mientras carga
        if (authStore.isLoading) {
          return const SplashScreen();
        }

        // Si está autenticado, ir al MainScreen
        if (authStore.isAuthenticated) {
          return const MainScreen();
        }

        // Si no está autenticado, ir al Login
        return const LoginScreen();
      },
    );
  }
}
