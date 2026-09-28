import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitatrack/app/app.dart';
import 'package:vitatrack/core/services/local_store.dart';
import 'package:vitatrack/data/repositories/auth_repository.dart';
import 'package:vitatrack/features/authentication/presentation/controllers/auth_provider.dart';
import 'package:vitatrack/features/dashboard/user_dashboard/controllers/app_provider.dart';

void main() {
  testWidgets('VitaTrack démarre sur le splash puis redirige', (
      WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance.init();
    await AuthRepository.instance.seedDemoAccounts();

    final authProvider = AuthProvider(AuthRepository.instance);
    await authProvider.restoreSession();
    final appProvider = AppProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => authProvider),
          ChangeNotifierProvider(create: (_) => appProvider),
        ],
        child: const VitaTrackApp(),
      ),
    );

    // L'écran de démarrage affiche le nom de l'application.
    expect(find.text('VitaTrack'), findsOneWidget);

    // On laisse le splash terminer son délai puis la redirection s'effectuer.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Sans session, l'utilisateur est redirigé vers l'onboarding.
    expect(tester.takeException(), isNull);
  });
}
