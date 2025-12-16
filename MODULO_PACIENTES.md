# Módulo de Pacientes

## Archivos Creados

### 1. Servicios
- **`lib/core/services/patients_service.dart`**
  - `getPatients(token)` - Obtiene todos los pacientes (GET /patients)
  - `getPatientById(token, id)` - Obtiene un paciente por ID (GET /patients/:id)
  - `createPatient(token, fullName, birthDate)` - Crea nuevo paciente (POST /patients)
  - `updatePatient(token, id, fullName?, birthDate?)` - Actualiza paciente (PATCH /patients/:id)
  - `deletePatient(token, id)` - Elimina paciente (DELETE /patients/:id)

### 2. Widgets
- **`lib/features/patients/widgets/patient_card.dart`**
  - Card reutilizable para mostrar información de pacientes
  - Incluye: avatar/iniciales, nombre, fecha de nacimiento, edad, fase, estado
  - Barra lateral de color según estado
  - Completamente personalizable con parámetros

### 3. Páginas
- **`lib/features/patients/pages/patients_page.dart`**
  - Lista completa de pacientes con datos del API
  - Barra de búsqueda por nombre
  - Filtros: "Todos", "Espasticidad Leve", "Fase Estudio"
  - Contador de pacientes activos
  - Pull-to-refresh para actualizar lista
  - Estado vacío con botón para agregar
  - Botón flotante (+) para crear nuevo paciente

- **`lib/features/patients/pages/new_patient_page.dart`**
  - Formulario para crear nuevo paciente
  - Campos: Nombre y Apellidos, Fecha de Nacimiento
  - DatePicker integrado
  - Toggle: "Iniciar tratamiento" (placeholder para futura funcionalidad)
  - Validación de campos
  - Integración con API POST /patients
  - Muestra quién está registrando el paciente

## Uso

### Obtener Lista de Pacientes
```dart
final token = context.read<AuthStore>().token;
final patients = await PatientsService.getPatients(token!);
```

### Crear Nuevo Paciente
```dart
final token = context.read<AuthStore>().token;
final newPatient = await PatientsService.createPatient(
  token: token!,
  fullName: 'María González',
  birthDate: '1990-05-15', // Formato: YYYY-MM-DD
);
```

### Navegar a Nueva Paciente
```dart
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const NewPatientPage()),
);

if (result == true) {
  // Paciente creado exitosamente, recargar lista
  _loadPatients();
}
```

## Formato de Datos API

### Request (Crear Paciente)
```json
{
  "fullName": "María González",
  "birthDate": "1990-05-15"
}
```

### Response
```json
{
  "patientId": 1,
  "fullName": "María González",
  "birthDate": "1990-05-15",
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

## Características Implementadas

✅ Lista de pacientes con integración API
✅ Búsqueda por nombre en tiempo real
✅ Filtros de categorías (preparados para backend)
✅ Contador de pacientes activos
✅ Cards con diseño profesional y colores dinámicos
✅ Formulario de nuevo paciente con validación
✅ DatePicker para fecha de nacimiento
✅ Cálculo automático de edad
✅ Formato de fechas DD/MM/YYYY
✅ Pull-to-refresh en lista
✅ Estado vacío con CTA
✅ Manejo de errores con SnackBars
✅ Loading states durante operaciones API

## Datos de UI Temporales

Los siguientes datos se generan automáticamente en la UI mientras el backend no los provea:
- **Fase del estudio**: FASE 1, FASE 2, FASE 3 (rotación)
- **Estado**: Estable (verde), Revisión (amarillo), Evaluación (rojo), Activo (verde), Finalizado (gris)
- **Color de barra lateral**: Verde, Amarillo, Rojo, Azul (rotación)
- **Número de registro**: #RES-XXXX (generado con patientId)

## Próximas Implementaciones

⏳ Página de detalle del paciente
⏳ Editar información del paciente
⏳ Eliminar paciente con confirmación
⏳ Filtros reales conectados al backend
⏳ Integración de "Iniciar tratamiento" con API
⏳ Estadísticas reales de pacientes
⏳ Exportar lista de pacientes
⏳ Paginación para listas grandes
