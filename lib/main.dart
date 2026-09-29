import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/constants/app_constants.dart';
import 'core/services/local_store.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/supabase_bootstrap.dart';
import 'core/services/supabase_sync_service.dart';
import 'data/models/user_model.dart';
import 'data/repositories/auth_repository.dart';
import 'features/authentication/presentation/controllers/auth_provider.dart';
import 'features/dashboard/user_dashboard/controllers/app_provider.dart';

import 'core/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Backend principal : Supabase (Auth + PostgREST + Storage).
  await SupabaseBootstrap.init();
  // Détection d'une réinitialisation du mot de passe : on s'abonne aux
  // changements d'état d'auth le plus tôt possible pour capter l'événement
  // `passwordRecovery` déclenché à l'ouverture du lien reçu par e-mail.
  AuthRepository.instance.startAuthRecoveryListener();
  // Firebase n'est utilisé que pour le push (FCM) — facultatif.
  await FirebaseBootstrap.init();

  // Formats de dates en français (utilisés par DateUtils).
  initializeDateFormatting('fr_FR');

  // Cache local (les repositories lisent ici de façon synchrone).
  await LocalStore.instance.init();

  // Comptes de secours locaux, uniquement si Supabase est indisponible.
  await AuthRepository.instance.seedDemoAccounts();

  final authProvider = AuthProvider(AuthRepository.instance);
  final appProvider = AppProvider();

  // Restauration de session éventuelle.
  final account = await authProvider.restoreSession();
  if (account != null) {
    // On attache tout de suite le contexte utilisateur depuis le cache local :
    // l'interface s'affiche sans attendre le réseau.
    if (account.role == UserRole.user) {
      appProvider.bindUser(UserModel.fromMap(account.profile));
    }
    if (SupabaseBootstrap.ready) {
      if (SupabaseSyncService.instance.hasRecentPull()) {
        // Cache frais : rafraîchissement en arrière-plan, puis relecture.
        SupabaseSyncService.instance
            .pullForCurrentAccount(role: account.role)
            .whenComplete(() => appProvider.reload());
      } else {
        // Premier lancement / cache périmé : on attend les données à jour.
        await SupabaseSyncService.instance
            .pullForCurrentAccount(role: account.role);
        if (account.role == UserRole.user) {
          await appProvider.reload();
        }
      }
    }
    if (FirebaseBootstrap.ready) {
      await FcmService.instance.init(account.id);
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => appProvider),
      ],
      child: const VitaTrackApp(),
    ),
  );
}
