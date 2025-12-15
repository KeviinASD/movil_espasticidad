import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movil_espasticidad/screens/splash_screen.dart';
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
    return MaterialApp(
      title: 'FisioLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Usa el tema del sistema
      home: const SplashScreen(),
    );
  }
}
