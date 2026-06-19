# Pixel Defender — Deploy & API

## Compilación Android (APK)

### Release
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Split por ABI (reducir tamaño)
```bash
flutter build apk --split-per-abi
# Outputs:
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
#   build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### App Bundle (recomendado para Play Store)
```bash
flutter build appbundle
# Output: build/app/outputs/bundle/release/app-release.aab
```

## Deploy con ADB

### Instalar APK en dispositivo conectado
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Instalar APK específico (split)
```bash
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Reinstalar forzado (si ya existe)
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Ver dispositivos conectados
```bash
adb devices -l
```

### Desinstalar
```bash
adb uninstall com.example.pixel_defender
```

### Ver logs del juego
```bash
adb logcat -s flutter
```

## Deploy a Google Play (futuro)
```bash
# 1. Generar AAB
flutter build appbundle --release

# 2. Subir a Google Play Console
#    - Ir a Producción / Pruebas internas
#    - Subir build/app/outputs/bundle/release/app-release.aab
```

## Variables de entorno útiles
```bash
export FLUTTER_BUILD_NUMBER=1
export FLUTTER_BUILD_NAME=0.1.0
```

## Comandos rápidos

| Comando                                     | Descripción                        |
|---------------------------------------------|------------------------------------|
| `flutter pub get`                           | Instalar dependencias              |
| `flutter clean`                             | Limpiar build previo               |
| `flutter build apk --release`               | Compilar APK                       |
| `adb install -r build/app/outputs/...apk`   | Instalar en dispositivo            |
| `adb uninstall com.example.pixel_defender`  | Desinstalar                        |
| `flutter run -d android`                    | Debug directo                      |
