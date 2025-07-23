# Instrukcje Budowania Flutter App na Różne Platformy

## Przegląd
Instrukcje do budowania aplikacji Squads na Android, Windows i Web oraz przygotowanie na przyszłe platformy.

## Wymagania wstępne

### Dla wszystkich platform:
```bash
# Sprawdź instalację Flutter
flutter doctor

# Aktualizuj dependencje
cd frontend
flutter pub get
```

### Dodatkowo dla Androida:
- Android Studio lub Android SDK
- Java 17+ / Android SDK 30+

### Dodatkowo dla Windows:
- Visual Studio 2022 z C++ workload
- Windows 10 SDK

### Dodatkowo dla Web:
- Przeglądarka z obsługą WebAssembly (Chrome, Firefox, Safari)

## Konfiguracja środowisk

### 1. Pliki środowiskowe

Utwórz pliki konfiguracyjne w `frontend/`:

**`.env.dev`** (development):
```env
API_BASE_URL=http://localhost:20757
API_VERSION=v1
IS_DEBUG=true
APP_VERSION=1.0.0-dev
```

**`.env.prod`** (production):
```env
API_BASE_URL=https://your-production-api.com
API_VERSION=v1
IS_DEBUG=false
APP_VERSION=1.0.0
```

**`.env.staging`** (staging - opcjonalnie):
```env
API_BASE_URL=https://staging-api.com
API_VERSION=v1
IS_DEBUG=false
APP_VERSION=1.0.0-staging
```

### 2. Modyfikacja konfiguracji dla środowisk

Zaktualizuj `lib/config/app_config.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String _envFile = '.env.prod'; // domyślnie production
  
  // Ustaw środowisko
  static void setEnvironment(String env) {
    switch (env) {
      case 'dev':
        _envFile = '.env.dev';
        break;
      case 'staging':
        _envFile = '.env.staging';
        break;
      case 'prod':
      default:
        _envFile = '.env.prod';
        break;
    }
  }
  
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';
  static String get apiUrl => '$apiBaseUrl/api/$apiVersion';
  
  static String get appName => 'Squads App';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  
  static bool get isDebug => dotenv.env['IS_DEBUG'] == 'true';
  
  static Future<void> initialize() async {
    await dotenv.load(fileName: _envFile);
  }
}
```

## Budowanie na Android

### Development build
```bash
cd frontend

# Ustaw środowisko dev i buduj debug APK
flutter build apk --debug --dart-define=ENV=dev

# Lub bezpośrednio na urządzenie
flutter run --dart-define=ENV=dev
```

### Production build
```bash
cd frontend

# Buduj release APK
flutter build apk --release --dart-define=ENV=prod

# Buduj AAB (Google Play Store)
flutter build appbundle --release --dart-define=ENV=prod

# Lokalizacja plików:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### Testowanie na emulatorze
```bash
# Lista dostępnych emulatorów
flutter emulators

# Uruchom emulator
flutter emulators --launch <emulator_id>

# Uruchom app na emulatorze
flutter run --dart-define=ENV=dev
```

## Budowanie na Windows

### Development build
```bash
cd frontend

# Buduj debug dla Windows
flutter build windows --debug --dart-define=ENV=dev
```

### Production build
```bash
cd frontend

# Buduj release dla Windows
flutter build windows --release --dart-define=ENV=prod

# Lokalizacja: build/windows/x64/runner/Release/
# Plik wykonywalny: squads.exe
```

### Pakowanie instalatora Windows (opcjonalnie)
```bash
# Zainstaluj msix (jeśli potrzebujesz instalator)
flutter pub add msix

# Dodaj do pubspec.yaml:
# msix:
#   display_name: Squads App
#   publisher_name: Your Name
#   identity_name: com.yourcompany.squads

# Buduj MSIX
flutter pub run msix:create
```

## Budowanie na Web

### Development build
```bash
cd frontend

# Uruchom dev server
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=ENV=dev

# Dostępne pod: http://localhost:3000
```

### Production build
```bash
cd frontend

# Buduj release dla web
flutter build web --release --dart-define=ENV=prod

# Buduj z optymalizacją rozmiaru
flutter build web --release --dart-define=ENV=prod --web-renderer canvaskit

# Lokalizacja: build/web/
```

### Serwowanie Web build
```bash
# Prostym serwerem Python
cd build/web
python -m http.server 8080

# Lub npm serve
npx serve build/web -s -l 8080

# Dostępne pod: http://localhost:8080
```

## Automatyzacja builds

### Skrypt PowerShell dla Windows

Utwórz `scripts/build_all.ps1`:
```powershell
param(
    [Parameter(Mandatory=$false)]
    [string]$env = "prod"
)

Write-Host "Building Squads App for environment: $env" -ForegroundColor Green

Set-Location frontend

# Android
Write-Host "Building Android APK..." -ForegroundColor Yellow
flutter build apk --release --dart-define=ENV=$env

# Windows
Write-Host "Building Windows..." -ForegroundColor Yellow
flutter build windows --release --dart-define=ENV=$env

# Web
Write-Host "Building Web..." -ForegroundColor Yellow
flutter build web --release --dart-define=ENV=$env

Write-Host "Build completed!" -ForegroundColor Green
Write-Host "Files location:" -ForegroundColor Cyan
Write-Host "  Android: build/app/outputs/flutter-apk/app-release.apk"
Write-Host "  Windows: build/windows/x64/runner/Release/"
Write-Host "  Web: build/web/"
```

Uruchomienie:
```powershell
# Production
./scripts/build_all.ps1 -env prod

# Development
./scripts/build_all.ps1 -env dev
```

### Skrypt Bash dla Linux/macOS

Utwórz `scripts/build_all.sh`:
```bash
#!/bin/bash

ENV=${1:-prod}

echo "Building Squads App for environment: $ENV"

cd frontend

# Android
echo "Building Android APK..."
flutter build apk --release --dart-define=ENV=$ENV

# Web
echo "Building Web..."
flutter build web --release --dart-define=ENV=$ENV

echo "Build completed!"
echo "Files location:"
echo "  Android: build/app/outputs/flutter-apk/app-release.apk"
echo "  Web: build/web/"
```

## Przygotowanie na przyszłe platformy

### iOS
```bash
# Gdy będziesz gotowy na iOS:
flutter build ios --release --dart-define=ENV=prod

# Wymaga macOS i Xcode
```

### macOS
```bash
# Budowanie dla macOS (wymaga macOS):
flutter build macos --release --dart-define=ENV=prod
```

### Linux
```bash
# Budowanie dla Linux:
flutter build linux --release --dart-define=ENV=prod
```

## CI/CD Pipeline przykład

### GitHub Actions (`.github/workflows/build.yml`):
```yaml
name: Build Multi-Platform

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    - name: Get dependencies
      run: |
        cd frontend
        flutter pub get
    - name: Build APK
      run: |
        cd frontend
        flutter build apk --release --dart-define=ENV=prod

  build-web:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    - name: Get dependencies
      run: |
        cd frontend
        flutter pub get
    - name: Build Web
      run: |
        cd frontend
        flutter build web --release --dart-define=ENV=prod

  build-windows:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    - name: Get dependencies
      run: |
        cd frontend
        flutter pub get
    - name: Build Windows
      run: |
        cd frontend
        flutter build windows --release --dart-define=ENV=prod
```

## Testowanie builds

### Testy przed releasem
```bash
cd frontend

# Uruchom testy jednostkowe
flutter test

# Uruchom testy integracyjne
flutter test integration_test/

# Analiza kodu
flutter analyze
```

### Testowanie na różnych urządzeniach
```bash
# Lista podłączonych urządzeń
flutter devices

# Uruchom na konkretnym urządzeniu
flutter run -d <device_id> --dart-define=ENV=dev
```

## Deployment

### Android (Google Play)
1. Podpisz AAB kluczem
2. Upload do Google Play Console
3. Konfiguruj release tracks (internal, alpha, beta, production)

### Web
```bash
# Upload build/web/ na hosting (np. Firebase, Netlify, Vercel)
# Lub serwuj przez nginx/Apache
```

### Windows
- Dystrybuuj przez Microsoft Store (MSIX)
- Lub bezpośredni download (ZIP z folderem Release)

## Rozwiązywanie problemów

### Problemy z buildem Android
```bash
# Wyczyść cache
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get

# Sprawdź Android SDK
flutter doctor --android-licenses
```

### Problemy z buildem Windows
```bash
# Sprawdź Visual Studio dependencies
flutter doctor

# Wyczyść build
flutter clean
```

### Problemy z buildem Web
```bash
# Sprawdź czy web jest włączony
flutter config --enable-web

# Wyczyść cache
flutter clean
```

## Monitorowanie rozmiaru builds

```bash
# Analiza rozmiaru Android APK
flutter build apk --analyze-size

# Analiza rozmiaru Web
flutter build web --analyze-size
```

Ten guide da Ci kompletny workflow dla wszystkich platform z konfiguracją środowisk! 