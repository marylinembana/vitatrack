# Fusion des deux versions VITATRACK

## Base utilisée

`vitatrack2` sert de base d'interface et d'architecture fonctionnelle :
- palette verte/orange ;
- champs de formulaires ;
- cartes et tableaux de bord ;
- navigation par rôle ;
- écrans utilisateur, nutritionniste et administrateur ;
- messagerie, notifications, journal, objectifs et suivi du poids.

## Base de données retenue

Le premier projet VITATRACK sert de référence Firestore :
- `users`
- `foods`
- `categories`
- `meals`
- `weightEntries`
- `nutritionPlans`
- `recommendations`
- `notifications`
- `activityLogs`

Une collection `nutritionGoals` et `conversations` complète le modèle pour couvrir toutes les fonctions présentes dans vitatrack2.

## Choix technique

Firebase est le backend principal :
- Firebase Authentication pour l'identité ;
- Cloud Firestore pour les données ;
- Firebase Storage est disponible pour les photos ;
- Firebase Cloud Messaging est inclus pour les notifications push.

Un cache `SharedPreferences` reste présent afin que l'interface soit testable hors connexion et que les données soient répliquées vers Firestore dès qu'un utilisateur Firebase est connecté.
