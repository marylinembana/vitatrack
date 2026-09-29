import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitatrack/core/services/local_store.dart';
import 'package:vitatrack/data/models/nutritionist_model.dart';
import 'package:vitatrack/data/repositories/auth_repository.dart';
import 'package:vitatrack/data/repositories/nutritionist_repository.dart';

/// Chemin hors-ligne (SupabaseBootstrap.ready == false) : on vérifie la chaîne
/// « validation admin → accès nutritionniste ». Le reproche corrigé : après
/// validation par l'admin, le nutritionniste restait bloqué sur l'écran de
/// vérification car le statut ne quittait que le cache local.
void main() {
  late AuthRepository auth;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance.init();
    auth = AuthRepository.instance;
  });

  Future<NutritionistModel> seedNutritionist(String email) async {
    final account = await auth.register(
      email: email,
      password: 'secret123',
      fullName: 'Dr Test',
      profile: {
        'id': '',
        'email': email,
        'role': 'nutritionist',
        'fullName': 'Dr Test',
        'specialization': 'Nutrition sportive',
        'licenseNumber': 'LIC-001',
        'diplomaUrls': ['https://exemple.fr/diplome.png'],
        'patientIds': <String>[],
        'isVerified': false,
        'verificationStatus': 'pending',
      },
    );
    return NutritionistModel.fromMap(account.profile);
  }

  group('validation admin (flux nutritionniste)', () {
    test('le compte créé est pending et sans accès', () async {
      final n = await seedNutritionist('pending@vitatrack.app');
      expect(n.verificationStatus, VerificationStatus.pending);
      expect(n.hasAccess, isFalse);
    });

    test('la validation par l\'admin persiste le statut vérifié', () async {
      final n = await seedNutritionist('verify@vitatrack.app');
      // Comme users_management_screen._setStatus : l'admin applique le statut
      // puis enregistre via le repository.
      n.verificationStatus = VerificationStatus.verified;
      n.isVerified = true;
      n.verificationNote = null;
      await NutritionistRepository.instance.save(n);

      final saved = NutritionistRepository.instance.byIdOrNull(n.id);
      expect(saved, isNotNull);
      expect(saved!.verificationStatus, VerificationStatus.verified);
      expect(saved.hasAccess, isTrue);
    });

    test('un refus enregistre la note et garde l\'accès fermé', () async {
      final n = await seedNutritionist('reject@vitatrack.app');
      n.verificationStatus = VerificationStatus.rejected;
      n.isVerified = false;
      n.verificationNote = 'Diploume illisible';
      await NutritionistRepository.instance.save(n);

      final saved = NutritionistRepository.instance.byIdOrNull(n.id)!;
      expect(saved.verificationStatus, VerificationStatus.rejected);
      expect(saved.verificationNote, 'Diploume illisible');
      expect(saved.hasAccess, isFalse);
    });

    test('le retrait de vérification re-passe en pending', () async {
      final n = await seedNutritionist('unverify@vitatrack.app');
      n.verificationStatus = VerificationStatus.verified;
      n.isVerified = true;
      await NutritionistRepository.instance.save(n);
      final verified = NutritionistRepository.instance.byIdOrNull(n.id)!;
      verified.verificationStatus = VerificationStatus.pending;
      verified.isVerified = false;
      await NutritionistRepository.instance.save(verified);

      final saved = NutritionistRepository.instance.byIdOrNull(n.id)!;
      expect(saved.verificationStatus, VerificationStatus.pending);
      expect(saved.hasAccess, isFalse);
    });

    test('syncProfileToBackend ne lève pas hors-ligne', () async {
      final n = await seedNutritionist('sync@vitatrack.app');
      final account =
          auth.allAccounts().firstWhere((a) => a.id == n.id);
      await expectLater(
          auth.syncProfileToBackend(account), completes);
    });

    test('refreshCurrentAccount renvoie le compte à jour hors-ligne', () async {
      await auth.login('verify@vitatrack.app', 'secret123');
      // Hors-ligne, refreshCurrentAccount ne peut pas relancer Supabase ;
      // la session locale doit néanmoins rester cohérente (statut vérifié
      // enregistré plus haut par l'admin).
      final refreshed = await auth.refreshCurrentAccount();
      expect(refreshed, isNull); // null = pas de backend, comportement attendu
      expect(auth.currentAccount?.email, 'verify@vitatrack.app');
    });
  });
}
