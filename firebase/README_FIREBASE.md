# Configuration Firebase VITATRACK

1. Crée le projet Firebase **VITATRACK**.
2. Active **Authentication > Email/Password**.
3. Crée **Cloud Firestore**.
4. Installe FlutterFire : `dart pub global activate flutterfire_cli`.
5. Dans le dossier du projet : `flutterfire configure`.
6. Déploie les règles/index : `firebase deploy --only firestore:rules,firestore:indexes`.
7. Importe `seed_foods.json` ou utilise `seed_foods.dart` depuis un environnement Dart configuré.

Le fichier `lib/firebase_options.dart` fourni est un modèle de secours. `flutterfire configure` doit le remplacer.

Collections : `users`, `foods`, `categories`, `meals`, `weightEntries`, `nutritionGoals`, `nutritionPlans`, `recommendations`, `notifications`, `activityLogs`, `conversations`.
