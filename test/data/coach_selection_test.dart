import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitatrack/app/constants/app_constants.dart';
import 'package:vitatrack/core/services/local_store.dart';
import 'package:vitatrack/data/models/nutritionist_model.dart';
import 'package:vitatrack/data/repositories/auth_repository.dart';
import 'package:vitatrack/data/repositories/nutritionist_repository.dart';

/// Flux « Mon coach » côté patient, chemin hors-ligne : seuls les
/// nutritionnistes VÉRIFIÉS sont proposés, et le patient peut enregistrer le
/// coach choisi sur son propre profil (nutritionistId).
void main() {
  late AuthRepository auth;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance.init();
    auth = AuthRepository.instance;
  });

  Future<NutritionistModel> seedNutritionist(
    String email, {
    required bool verified,
  }) async {
    final account = await auth.register(
      email: email,
      password: 'secret123',
      fullName: 'Dr $email',
      role: UserRole.nutritionist,
      profile: {
        'id': '',
        'email': email,
        'role': 'nutritionist',
        'fullName': 'Dr Test',
        'specialization': 'Nutrition générale',
        'licenseNumber': 'LIC-${email.hashCode}',
        'diplomaUrls': ['https://exemple.fr/diplome.png'],
        'patientIds': <String>[],
        'isVerified': verified,
        'verificationStatus': verified ? 'verified' : 'pending',
      },
    );
    return NutritionistModel.fromMap(account.profile);
  }

  group('annuaire des coachs', () {
    test('verified() ne renvoie que les nutritionnistes vérifiés', () async {
      await seedNutritionist('coach.ok@vitatrack.app', verified: true);
      await seedNutritionist('coach.pending@vitatrack.app', verified: false);

      final verified = NutritionistRepository.instance.verified();
      expect(verified, isNotEmpty);
      expect(
        verified.every((n) => n.hasAccess),
        isTrue,
        reason: 'tous les coachs proposés doivent être vérifiés',
      );
      expect(
        verified.any((n) => n.email == 'coach.pending@vitatrack.app'),
        isFalse,
      );
    });
  });

  group('association patient → coach', () {
    test('le patient enregistre le coach choisi sur son profil', () async {
      final coach =
          await seedNutritionist('assign.coach@vitatrack.app', verified: true);

      await auth.register(
        email: 'patient@vitatrack.app',
        password: 'secret123',
        fullName: 'Jean Patient',
        profile: {
          'id': '',
          'email': 'patient@vitatrack.app',
          'role': 'user',
          'fullName': 'Jean Patient',
        },
      );
      await auth.login('patient@vitatrack.app', 'secret123');

      final account = auth.currentAccount!;
      account.profile['nutritionistId'] = coach.id;
      await auth.updateProfile(account);

      final reloaded =
          auth.allAccounts().firstWhere((a) => a.id == account.id);
      expect(reloaded.profile['nutritionistId'], coach.id);
    });
  });
}
