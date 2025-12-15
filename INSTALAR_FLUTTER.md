# Guía de Instalación de Flutter SDK

## Método 1: Descarga Manual (Recomendado)

1. **Descargar Flutter SDK:**
   - Visita: https://docs.flutter.dev/get-started/install/windows
   - O descarga directamente: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip
   - Tamaño aproximado: ~1.5 GB

2. **Extraer el archivo:**
   - Extrae el contenido del ZIP en: `C:\src\flutter`
   - O en: `%LOCALAPPDATA%\flutter` (C:\Users\TU_USUARIO\AppData\Local\flutter)

3. **Agregar al PATH:**
   - Presiona `Win + R`, escribe `sysdm.cpl` y presiona Enter
   - Ve a la pestaña "Opciones avanzadas"
   - Haz clic en "Variables de entorno"
   - En "Variables del usuario", selecciona "Path" y haz clic en "Editar"
   - Haz clic en "Nuevo" y agrega: `C:\src\flutter\bin` (o la ruta donde extrajiste Flutter)
   - Haz clic en "Aceptar" en todas las ventanas

4. **Verificar instalación:**
   - Cierra y vuelve a abrir PowerShell
   - Ejecuta: `flutter doctor`

## Método 2: Usando Git (Si tienes Git instalado)

```powershell
cd C:\src
git clone https://github.com/flutter/flutter.git -b stable
```

Luego agrega `C:\src\flutter\bin` al PATH como se indica arriba.

## Método 3: Usando Scoop (Gestor de paquetes)

Si tienes Scoop instalado:

```powershell
scoop bucket add extras
scoop install flutter
```

## Después de Instalar

1. **Cierra y vuelve a abrir PowerShell**

2. **Verifica la instalación:**
   ```powershell
   flutter doctor
   ```

3. **Instala las dependencias faltantes** que indique `flutter doctor`

4. **Navega a tu proyecto:**
   ```powershell
   cd "D:\8vo\inteligencia de negocios\extra\movil_espasticidad"
   ```

5. **Obtén las dependencias:**
   ```powershell
   flutter pub get
   ```

6. **Ejecuta el proyecto:**
   ```powershell
   flutter run
   ```

## Requisitos Adicionales

- **Android Studio** (para desarrollo Android): https://developer.android.com/studio
- **Visual Studio** (para desarrollo Windows): https://visualstudio.microsoft.com/
- **Xcode** (solo para macOS, para desarrollo iOS)

## Solución de Problemas

Si `flutter doctor` muestra problemas:

- **Android toolchain**: Instala Android Studio y el SDK de Android
- **Visual Studio**: Instala Visual Studio con las herramientas de desarrollo de escritorio de C++
- **Android licenses**: Ejecuta `flutter doctor --android-licenses` y acepta todas las licencias

