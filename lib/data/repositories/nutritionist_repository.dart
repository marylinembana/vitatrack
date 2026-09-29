import '../models/nutritionist_model.dart';
import 'auth_repository.dart';

/// Repository des profils nutritionnistes (stockés dans les comptes).
class NutritionistRepository {
  NutritionistRepository._();
  static final NutritionistRepository instance = NutritionistRepository._();

  final AuthRepository _auth = AuthRepository.instance;

  List<NutritionistModel> all() => _auth
      .allAccounts()
      .where((a) => a.role == 'nutritionist')
      .map((a) => NutritionistModel.fromMap(a.profile))
      .toList();

  /// Nutritionnistes **vérifiés** (validés par l'admin) : seuls ceux-là sont
  /// visibles et choisissables par un patient comme coach.
  List<NutritionistModel> verified() =>
      all().where((n) => n.hasAccess).toList();

  NutritionistModel? byId(String id) {
    final account = _auth.allAccounts().firstWhere(
          (a) => a.id == id,
          orElse: () => throw StateError('introuvable'),
        );
    return NutritionistModel.fromMap(account.profile);
  }

  NutritionistModel? byIdOrNull(String id) {
    final accounts =
        _auth.allAccounts().where((a) => a.id == id).toList();
    if (accounts.isEmpty) return null;
    return NutritionistModel.fromMap(accounts.first.profile);
  }

  Future<void> save(NutritionistModel nutritionist) async {
    final accounts = _auth.allAccounts();
    final index =
        accounts.indexWhere((a) => a.id == nutritionist.id);
    if (index == -1) return;
    accounts[index].profile = nutritionist.toMap();
    await _auth.saveAccounts(accounts);
    // Persistance réelle : sans cet upsert explicite, la validation admin
    // (statut, note) ne toucherait que le cache local de l'appareil admin
    // et le nutritionniste resterait bloqué sur l'écran de vérification.
    await _auth.syncProfileToBackend(accounts[index]);
  }

  Future<void> addPatient(String nutritionistId, String patientId) async {
    final nutritionist = byIdOrNull(nutritionistId);
    if (nutritionist == null) return;
    if (!nutritionist.patientIds.contains(patientId)) {
      nutritionist.patientIds.add(patientId);
      await save(nutritionist);
    }
  }

  Future<void> removePatient(String nutritionistId, String patientId) async {
    final nutritionist = byIdOrNull(nutritionistId);
    if (nutritionist == null) return;
    nutritionist.patientIds.remove(patientId);
    await save(nutritionist);
  }
}
