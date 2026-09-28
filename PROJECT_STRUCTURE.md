# Structure VITATRACK 2.0

- `lib/app/` : thème, constantes, routes
- `lib/core/` : widgets, erreurs, stockage local, Firebase bootstrap/synchronisation
- `lib/data/models/` : modèles utilisateur, aliments, repas, objectifs, plans, notifications, messages
- `lib/data/repositories/` : accès métier et cache synchronisé
- `lib/features/authentication/` : inscription/connexion/récupération mot de passe
- `lib/features/dashboard/` : dashboard utilisateur
- `lib/features/foods/` : catalogue, recherche, catégories, détail
- `lib/features/meals/` : ajout repas, journal, détail
- `lib/features/goals/` : objectifs nutritionnels
- `lib/features/weight/` : suivi du poids
- `lib/features/recommendations/` : recommandations
- `lib/features/notifications/` : notifications
- `lib/features/messaging/` : conversations nutritionniste/utilisateur
- `lib/features/nutritionist/` : patients, plans, rapports, profil pro
- `lib/features/admin/` : utilisateurs, aliments, catégories, statistiques, activités
- `firebase/` : règles, index, seed et documentation Firebase
- `scripts/` : aide d'installation Windows
