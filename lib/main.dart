import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/constants/app_constants.dart';
import 'core/services/local_store.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/firebase_sync_service.dart';
import 'data/datasources/demo_seeder.dart';
import 'data/models/user_model.dart';
import 'data/repositories/auth_repository.dart';
import 'features/authentication/presentation/controllers/auth_provider.dart';
import 'features/dashboard/user_dashboard/controllers/app_provider.dart';

import 'core/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseBootstrap.init();

  // Formats de dates en français (utilisés par DateUtils).
  initializeDateFormatting('fr_FR');

  // Persistance locale (seed Firebase/backend plus tard).
  await LocalStore.instance.init();

  // Comptes et données de démonstration au premier lancement.
  await AuthRepository.instance.seedDemoAccounts();
  await DemoSeeder.seedIfFirstRun();

  final authProvider = AuthProvider(AuthRepository.instance);
  final appProvider = AppProvider();

  // Restauration de session éventuelle.
  final account = await authProvider.restoreSession();
  if (account != null && account.role == UserRole.user) {
    appProvider.bindUser(UserModel.fromMap(account.profile));
  }
  if (account != null && FirebaseBootstrap.ready) {
    await FirebaseSyncService.instance.pullForCurrentAccount(role: account.role);
    await FcmService.instance.init(account.id);
    if (account.role == UserRole.user) {
      appProvider.bindUser(UserModel.fromMap(account.profile));
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
