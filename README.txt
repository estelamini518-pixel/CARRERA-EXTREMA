TURBO RACING: CARRERA AL VACÍO

Proyecto Flutter preparado para compilar el APK con GitHub Actions.

Contenido:
- lib/main.dart: juego completo con nave, meteoritos, sombra perseguidora, agujero negro, niveles, vidas y puntos.
- pubspec.yaml: configuración Flutter sin claves YAML duplicadas.
- .github/workflows/build-apk.yml: genera APK Android y lo publica como Artifact.
- No incluye carpeta test para evitar el error heredado de MyApp/widget_test.dart.

Para compilar:
1. Sube todos los archivos y carpetas al repositorio, conservando la ruta .github/workflows/build-apk.yml.
2. Abre Actions.
3. Ejecuta "Compilar Turbo Racing".
4. Cuando termine en verde, descarga el Artifact "Turbo-Racing-APK".
5. Extrae el ZIP del Artifact para obtener app-release.apk.
