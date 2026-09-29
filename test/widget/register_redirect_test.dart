import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitatrack/app/routes/route_generator.dart';
import 'package:vitatrack/core/services/local_store.dart';
import 'package:vitatrack/data/repositories/auth_repository.dart';
import 'package:vitatrack/features/authentication/presentation/controllers/auth_provider.dart';
import 'package:vitatrack/features/dashboard/user_dashboard/controllers/app_provider.dart';

/// RÉGRESSION : après une inscription patient, l'utilisateur doit être lié à
/// l'AppProvider puis redirigé vers l'assistant d'objectif (GoalSetupScreen),
/// lequel doit afficher le formulaire (et non « Aucun utilisateur connecté »).
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance.init();
  });

  testWidgets('inscription patient redirige vers l\'onboarding avec utilisateur lié',
      (tester) async {
    final authProvider = AuthProvider(AuthRepository.instance);
    final appProvider = AppProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => authProvider),
          ChangeNotifierProvider(create: (_) => appProvider),
        ],
        child: MaterialApp(
          initialRoute: '/register',
          onGenerateRoute: RouteGenerator.generateRoute,
        ),
      ),
    );

    // 4 champs en mode patient : Nom, Email, Mot de passe, Confirmation.
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), 'Nouveau Patient');
    await tester.enterText(fields.at(1), 'nouveau@vitatrack.app');
    await tester.enterText(fields.at(2), 'motdepasse123');
    await tester.enterText(fields.at(3), 'motdepasse123');

    final button = find.widgetWithText(ElevatedButton, 'S\'inscrire');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    // On a bien atteint l'assistant d'objectif (titre de l'appBar).
    expect(find.text('Définir votre objectif'), findsOneWidget);
    // Le formulaire est rendu, et non l'état vide.
    expect(find.text('Aucun utilisateur connecté.'), findsNothing);
    expect(find.text('Sexe'), findsOneWidget);

    // L'utilisateur est correctement lié au tableau de bord.
    expect(appProvider.user, isNotNull);
    expect(appProvider.user?.email, 'nouveau@vitatrack.app');
    expect(authProvider.isSignedIn, isTrue);
  });
}
