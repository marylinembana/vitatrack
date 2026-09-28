Write-Host "=== VITATRACK - préparation Windows ===" -ForegroundColor Green
flutter --version
if ($LASTEXITCODE -ne 0) { throw "Flutter n'est pas disponible dans PATH." }
flutter pub get
dart pub global activate flutterfire_cli
Write-Host "Étape suivante : flutterfire configure" -ForegroundColor Cyan
Write-Host "Puis : firebase deploy --only firestore:rules,firestore:indexes" -ForegroundColor Cyan
