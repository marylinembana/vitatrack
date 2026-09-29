import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitatrack/core/services/local_store.dart';
import 'package:vitatrack/data/repositories/auth_repository.dart';
import 'package:vitatrack/features/authentication/presentation/controllers/auth_provider.dart';
import 'package:vitatrack/features/authentication/presentation/screens/login_screen.dart';
import 'package:vitatrack/features/dashboard/user_dashboard/controllers/app_provider.dart';

/// L'écran de connexion ne doit plus afficher d'encart « comptes de démonstration ».
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance.init();
  });

  Widget wrap() => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository.instance)),
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      );

  testWidgets('affiche le formulaire de connexion', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Bon retour !'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
  });

  testWidgets('aucun encart de compte de démonstration', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.textContaining('démonstration'), findsNothing);
    expect(find.textContaining('demo1234'), findsNothing);
    expect(find.textContaining('Comptes de'), findsNothing);
  });

  testWidgets('les champs sont vides (pas d\'identifiants pré-remplis)', (tester) async {
    await tester.pumpWidget(wrap());

    final fields = find.byType(TextFormField);
    for (final f in tester.widgetList<TextFormField>(fields)) {
      final controller = f.controller;
      expect(controller == null || controller.text.isEmpty, isTrue);
    }
  });
}
