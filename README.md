# SmartPOS Cloud

Aplicación Flutter (WebView) para cargar la plataforma web de OralB en Android, iOS y Web.

## Tecnologías

- Flutter / Dart
- WebView (`webview_flutter`)
- FlutterFlow (base del proyecto)

## Requisitos

- Flutter SDK estable
- Dart SDK compatible con la restricción definida en `/pubspec.yaml`
- Android Studio y/o Xcode (según plataforma objetivo)

## Ejecución local

1. Instalar dependencias:
   ```bash
   flutter pub get
   ```
2. Ejecutar en modo desarrollo:
   ```bash
   flutter run
   ```

## Validación

```bash
flutter analyze
flutter test
```

## Estructura principal

- `/lib/main.dart`: punto de entrada.
- `/lib/pages/home_page/home_page_widget.dart`: WebView principal y manejo de conectividad/errores.
- `/assets`: recursos estáticos.

## Publicación y seguridad

Para mantener el repositorio publicable:

- No subir credenciales, llaves privadas o archivos `.env`.
- Mantener fuera del control de versiones archivos de firma/certificados.
- Revisar que no existan tokens, secretos o instrucciones internas antes de publicar.

Este repositorio ya fue revisado para retirar o prevenir contenido sensible común mediante reglas de `.gitignore`.
