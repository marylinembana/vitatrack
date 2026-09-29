import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitatrack/app/constants/app_constants.dart';
import 'package:vitatrack/core/errors/app_exception.dart';
import 'package:vitatrack/core/services/local_store.dart';
import 'package:vitatrack/data/repositories/auth_repository.dart';

/// Ces tests exercent le chemin HORS-LIGNE (SupabaseBootstrap.ready == false) :
/// le repository utilise le cache local hashé. On valide le comportement
/// fonctionnel de l'authentification sans dépendre du backend.
void main() {
  late AuthRepository repo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance.init();
    repo = AuthRepository.instance;
    // Compte partagé pour le groupe « login » (créé une seule fois).
    await repo.register(
      email: 'login@vitatrack.app',
      password: 'rightpass',
      fullName: 'Login User',
      profile: {
        'id': '',
        'email': 'login@vitatrack.app',
        'role': UserRole.user,
        'fullName': 'Login User'
      },
    );
  });

  Map<String, dynamic> profileOf(String email, {String role = UserRole.user}) =>
      {'id': '', 'email': email, 'role': role, 'fullName': 'Test User'};

  group('register (hors-ligne)', () {
    test('crée un compte, définit la session courante', () async {
      final account = await repo.register(
        email: 'reg1@vitatrack.app',
        password: 'secret123',
        fullName: 'Reg One',
        profile: profileOf('reg1@vitatrack.app'),
      );

      expect(account.id, isNotEmpty);
      expect(account.email, 'reg1@vitatrack.app');
      expect(account.role, UserRole.user);
      expect(repo.currentAccount?.id, account.id);
      expect(repo.allAccounts().any((a) => a.email == 'reg1@vitatrack.app'), isTrue);
    });

    test('normalise l\'email (minuscules + trim)', () async {
      final account = await repo.register(
        email: '  MixedCase@VitaTrack.App ',
        password: 'secret123',
        fullName: 'Norm',
        profile: profileOf('x'),
      );
      expect(account.email, 'mixedcase@vitatrack.app');
    });

    test('rejette un email déjà utilisé', () async {
      await repo.register(
        email: 'dup@vitatrack.app',
        password: 'secret123',
        fullName: 'Dup A',
        profile: profileOf('dup@vitatrack.app'),
      );
      expect(
        () => repo.register(
          email: 'dup@vitatrack.app',
          password: 'other123',
          fullName: 'Dup B',
          profile: profileOf('dup@vitatrack.app'),
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('login (hors-ligne)', () {
    test('authentifie avec de bons identifiants', () async {
      final account = await repo.login('login@vitatrack.app', 'rightpass');
      expect(account.email, 'login@vitatrack.app');
      expect(repo.currentAccount, isNotNull);
    });

    test('rejette un mot de passe incorrect', () async {
      await expectLater(
        repo.login('login@vitatrack.app', 'wrongpass'),
        throwsA(isA<AuthException>()
            .having((e) => e.code, 'code', 'invalid-credential')),
      );
    });

    test('rejette un email inconnu', () async {
      await expectLater(
        repo.login('ghost@vitatrack.app', 'whatever'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('session & logout', () {
    test('restoreSession retrouve le compte connecté', () async {
      final account = await repo.register(
        email: 'sess@vitatrack.app',
        password: 'secret123',
        fullName: 'Sess',
        profile: profileOf('sess@vitatrack.app'),
      );
      final restored = await repo.restoreSession();
      expect(restored?.id, account.id);
    });

    test('logout efface la session courante', () async {
      await repo.register(
        email: 'out@vitatrack.app',
        password: 'secret123',
        fullName: 'Out',
        profile: profileOf('out@vitatrack.app'),
      );
      await repo.logout();
      expect(repo.currentAccount, isNull);
      expect(LocalStore.instance.readString(StoreKeys.session), isNull);
    });
  });

  group('changePasswordWithReauth (hors-ligne)', () {
    test('refuse le mot de passe actuel incorrect puis accepte le nouveau', () async {
      await repo.register(
        email: 'pwd@vitatrack.app',
        password: 'old12345',
        fullName: 'Pwd',
        profile: profileOf('pwd@vitatrack.app'),
      );

      await expectLater(
        repo.changePasswordWithReauth('bad', 'new12345'),
        throwsA(isA<AuthException>()),
      );

      await repo.changePasswordWithReauth('old12345', 'new12345');
      final account = await repo.login('pwd@vitatrack.app', 'new12345');
      expect(account.email, 'pwd@vitatrack.app');
    });
  });

  group('hashForDemo', () {
    test('deterministe pour un même mot de passe', () {
      expect(repo.hashForDemo('abc'), repo.hashForDemo('abc'));
      expect(repo.hashForDemo('abc'), isNot(repo.hashForDemo('abd')));
    });
  });

  group('réinitialisation mot de passe (hors-ligne)', () {
    test('sendPasswordReset : email inconnu renvoie une erreur', () async {
      await expectLater(
        repo.sendPasswordReset('ghost@nowhere.app'),
        throwsA(isA<AuthException>()),
      );
    });

    test('sendPasswordReset : email connu ne lève pas', () async {
      await repo.register(
        email: 'reset@vitatrack.app',
        password: 'old12345',
        fullName: 'Reset',
        profile: profileOf('reset@vitatrack.app'),
      );
      await repo.sendPasswordReset('reset@vitatrack.app');
    });

    test('completePasswordReset : valide la longueur puis met à jour le compte',
        () async {
      await repo.login('reset@vitatrack.app', 'old12345');
      await expectLater(
        repo.completePasswordReset('123'),
        throwsA(isA<AuthException>()),
      );
      await repo.completePasswordReset('brandnew1');
      final account = await repo.login('reset@vitatrack.app', 'brandnew1');
      expect(account.email, 'reset@vitatrack.app');
      expect(repo.isPasswordRecovery, isFalse);
    });
  });
}
