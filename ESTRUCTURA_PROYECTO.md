# 📱 FisioLab - Aplicación Móvil

Aplicación móvil para el sistema de diagnóstico de espasticidad desarrollada con Flutter.

## 🏗️ Arquitectura del Proyecto

El proyecto sigue una **arquitectura por features** escalable y mantenible, ideal para trabajo en equipos.

```
lib/
├── main.dart                          # Punto de entrada de la app
├── core/                              # Funcionalidades compartidas
│   ├── models/                        # Modelos de datos globales
│   │   ├── user_model.dart           # Modelo de usuario
│   │   ├── auth_response_model.dart  # Respuesta de autenticación
│   │   └── patient_model.dart        # Modelo de paciente
│   ├── providers/                     # State management (Provider)
│   │   └── auth_store.dart           # ⭐ Store global de autenticación
│   └── services/                      # Servicios compartidos
│       └── storage_service.dart      # Almacenamiento seguro
├── features/                          # Features por módulo
│   ├── home/                         # 🏠 Feature: Home
│   │   ├── pages/
│   │   │   └── home_page.dart       # Página principal
│   │   └── widgets/                  # Widgets del home
│   │       ├── stat_card.dart       # Card de estadísticas
│   │       └── quick_action_card.dart
│   ├── patients/                     # 👥 Feature: Pacientes
│   │   ├── pages/
│   │   │   └── patients_page.dart
│   │   ├── widgets/                  # Widgets específicos
│   │   └── services/                 # Servicios del módulo
│   ├── research/                     # 🔬 Feature: Investigación
│   │   └── pages/
│   │       └── research_page.dart
│   ├── profile/                      # 👤 Feature: Perfil
│   │   └── pages/
│   │       └── profile_page.dart
│   └── main/                         # 🗂️ Pantalla principal con navegación
│       └── main_screen.dart         # Bottom navigation
├── screens/                          # Pantallas generales (auth, etc)
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   └── register_screen.dart
├── services/                         # Servicios de API
│   └── auth_service.dart            # ⭐ Servicio de autenticación
├── theme/                            # Tema de la aplicación
│   └── app_theme.dart               # Colores, tipografías, estilos
└── .env                             # Variables de entorno
```

## 🎯 Características Implementadas

### ✅ Sistema de Autenticación
- **Login completo** con la API de NestJS
- **Almacenamiento seguro** de tokens con Flutter Secure Storage
- **Estado global** con Provider (AuthStore)
- **Persistencia de sesión** entre reinicios

### ✅ Home Page
- Diseño profesional según mockup
- Cards de estadísticas (Pacientes, Críticos, Ensayos)
- Acceso rápido a funciones principales
- Gráfico de progreso con fl_chart
- Totalmente responsive

### ✅ Navegación
- Bottom Navigation Bar personalizado
- 4 secciones: Home, Pacientes, Investigar, Perfil
- Transiciones suaves

### ✅ Perfil de Usuario
- Información completa del usuario
- Cerrar sesión con confirmación
- Diseño moderno con avatar

## 🔐 Sistema de Estado (AuthStore)

El **AuthStore** es el corazón del manejo de estado de autenticación:

### Uso del AuthStore

```dart
// Obtener instancia del store
final authStore = context.watch<AuthStore>();

// Verificar si está autenticado
if (authStore.isAuthenticated) {
  // Usuario logueado
}

// Obtener usuario actual
final user = authStore.currentUser;
print('Hola ${user?.fullName}');

// Obtener token para API calls
final token = authStore.token;

// Login
await authStore.login(
  user: userModel,
  token: 'jwt_token_here',
);

// Logout
await authStore.logout();
```

### Token en API Calls

Para hacer peticiones autenticadas a tu API:

```dart
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// En cualquier widget/servicio
Future<void> fetchData(BuildContext context) async {
  final authStore = context.read<AuthStore>();
  final token = authStore.token;

  final response = await http.get(
    Uri.parse('http://localhost:3030/patients'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // ⭐ Token aquí
    },
  );

  // Manejar respuesta...
}
```

## 🚀 Cómo Iniciar

### 1. Configurar Variables de Entorno

Edita el archivo `.env`:

```env
API_BASE_URL=http://localhost:3030
ENVIRONMENT=development
```

**Para dispositivo físico:**
- Android: `http://10.0.2.2:3030` (emulador) o `http://TU_IP:3030` (físico)
- iOS: `http://TU_IP:3030`

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Ejecutar

```bash
# Iniciar tu backend en el puerto 3030
# Luego ejecutar la app
flutter run
```

## 📦 Dependencias Principales

```yaml
dependencies:
  provider: ^6.1.1              # State management
  http: ^1.2.2                   # API calls
  flutter_dotenv: ^5.1.0         # Variables de entorno
  flutter_secure_storage: ^9.0.0 # Almacenamiento seguro de tokens
  google_fonts: ^6.2.1           # Fuentes (Space Grotesk, Noto Sans)
  fl_chart: ^0.69.0              # Gráficos
```

## 👥 Trabajo en Equipo

### Estructura por Features

Cada feature es **independiente** y contiene:
- **pages/**: Pantallas del feature
- **widgets/**: Widgets reutilizables del feature
- **services/**: Lógica de negocio específica (opcional)
- **models/**: Modelos específicos (opcional)

### Cómo Agregar un Nuevo Feature

1. Crear carpeta en `lib/features/nombre_feature/`
2. Crear subcarpetas: `pages/`, `widgets/`, `services/`
3. Implementar tu lógica
4. Importar donde sea necesario

**Ejemplo: Agregar feature de Citas**

```
lib/features/appointments/
├── pages/
│   ├── appointments_list_page.dart
│   └── appointment_detail_page.dart
├── widgets/
│   └── appointment_card.dart
└── services/
    └── appointments_service.dart
```

### Separación de Responsabilidades

- **Páginas**: Solo UI y manejo de eventos
- **Widgets**: Componentes reutilizables
- **Services**: Lógica de negocio y llamadas a API
- **Providers**: Estado global (usar solo cuando sea necesario)
- **Models**: Estructuras de datos

## 🎨 Tema y Estilos

El proyecto usa un sistema de temas centralizado en `lib/theme/app_theme.dart`:

```dart
// Usar colores del tema
AppTheme.primary
AppTheme.backgroundDark
AppTheme.textPrimary

// Usar tipografía
GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold)
GoogleFonts.notoSans(fontSize: 14)
```

## 🔧 Agregar Más Endpoints

### 1. Crear Servicio

```dart
// lib/features/patients/services/patients_service.dart
import 'package:http/http.dart' as http;

class PatientsService {
  final String baseUrl = 'http://localhost:3030';

  Future<List<dynamic>> getPatients(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    // Procesar respuesta...
  }
}
```

### 2. Usar en Página

```dart
// lib/features/patients/pages/patients_page.dart
import 'package:provider/provider.dart';
import '../../../core/providers/auth_store.dart';

class PatientsPage extends StatefulWidget {
  // ...
  
  Future<void> _loadPatients() async {
    final authStore = context.read<AuthStore>();
    final token = authStore.token;
    
    final service = PatientsService();
    final patients = await service.getPatients(token!);
    
    setState(() {
      _patients = patients;
    });
  }
}
```

## 📱 Pantallas Disponibles

1. **SplashScreen**: Pantalla de carga inicial
2. **LoginScreen**: Autenticación
3. **MainScreen**: Navegación principal con 4 tabs
4. **HomePage**: Dashboard principal
5. **PatientsPage**: Lista de pacientes (placeholder)
6. **ResearchPage**: Investigación (placeholder)
7. **ProfilePage**: Perfil del usuario

## 🔐 Flujo de Autenticación

```
1. App inicia → AuthStore.initialize()
2. ¿Hay token guardado?
   → Sí: MainScreen (autenticado)
   → No: LoginScreen

3. Usuario hace login → AuthService.login()
4. AuthStore guarda user + token
5. Navigator → MainScreen
6. Todas las páginas tienen acceso al token vía AuthStore
```

## 📝 Próximos Pasos

- [ ] Implementar lista de pacientes real con API
- [ ] Agregar funcionalidad de nuevo paciente
- [ ] Implementar Escala Ashworth
- [ ] Agregar citas y calendario
- [ ] Implementar notificaciones
- [ ] Agregar búsqueda de tratamientos
- [ ] Tests unitarios y de integración

## 🐛 Troubleshooting

### Error de conexión
- Verifica que tu backend esté corriendo
- Revisa la URL en `.env`
- En dispositivo físico, usa tu IP local

### Token no persiste
- Verifica que Flutter Secure Storage esté configurado correctamente
- En Android, asegúrate de tener los permisos necesarios

### Hot reload no funciona
- Usa Hot Restart (`R` en terminal o botón en IDE)
- Los cambios en el Store requieren restart

---

**Desarrollado con ❤️ por el equipo de FisioLab**
