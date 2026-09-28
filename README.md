# VITATRACK 2.0 — Fusion UI + Firebase

Cette archive prend **vitatrack2 comme base visuelle et fonctionnelle** (couleurs, champs, formulaires, dashboards, écrans utilisateur/nutritionniste/admin) et réinjecte le **schéma Firestore du premier VITATRACK**.

## Ce qui est conservé/amélioré
- interface Material 3 moderne avec palette verte/orange de vitatrack2 ;
- formulaires complets ;
- dashboards utilisateur, nutritionniste et administrateur ;
- journal alimentaire, objectifs, poids, recommandations, notifications et messagerie ;
- gestion des aliments/catégories et statistiques ;
- données camerounaises de démonstration ;
- Firebase Authentication + Cloud Firestore ;
- cache local de secours pour tester l'interface avant configuration Firebase.

## Installation

```powershell
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
flutter run
```

Dans Firebase : active **Authentication > Email/Password**, crée Firestore, puis déploie :

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

Les collections principales sont : `users`, `foods`, `categories`, `meals`, `weightEntries`, `nutritionGoals`, `nutritionPlans`, `recommendations`, `notifications`, `activityLogs`, `conversations`.

## Comptes démo hors Firebase
Si Firebase n'est pas encore configuré, les comptes locaux de démonstration restent disponibles :
- user@vitatrack.app / demo1234
- nutritionist@vitatrack.app / demo1234
- admin@vitatrack.app / demo1234

Une fois Firebase configuré, les comptes réels doivent être créés dans Firebase Authentication. Le profil/role est stocké dans `users/{uid}`.

## Données nutritionnelles
Les valeurs fournies pour les aliments camerounais sont des données initiales illustratives. Elles doivent être validées par une source nutritionnelle fiable avant une utilisation médicale ou professionnelle.
