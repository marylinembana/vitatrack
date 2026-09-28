import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/user_model.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import '../../dashboard/user_dashboard/controllers/app_provider.dart';

/// Assistant de définition d'objectif (post-inscription ou modification).
/// Calcule les besoins caloriques avec la formule de Mifflin-St Jeor.
class GoalSetupScreen extends StatefulWidget {
  /// true = premier réglage après inscription (sinon simple modification).
  final bool isOnboarding;
  const GoalSetupScreen({super.key, this.isOnboarding = false});

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final UserModel? _user = context.read<AppProvider>().user;

  late Gender _gender = _user?.gender ?? Gender.male;
  late final TextEditingController _birthYear = TextEditingController(
      text: '${DateTime.now().year - (_user?.age ?? 30)}');
  late final TextEditingController _height =
      TextEditingController(text: (_user?.heightCm ?? 170).toString());
  late final TextEditingController _weight = TextEditingController(
      text: (_user?.targetWeightKg ?? 70).toStringAsFixed(0));
  late double _activity = _user?.activityFactor ?? 1.375;
  late GoalType _goalType = _user?.goalType ?? GoalType.maintain;

  bool get _hasUser => _user != null;

  @override
  void dispose() {
    _birthYear.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double get _age {
    final y = int.tryParse(_birthYear.text.trim());
    return (y == null) ? 30 : (DateTime.now().year - y).toDouble();
  }

  double get _recommended {
    final bmr = NutritionCalculator.bmr(
      weightKg: double.tryParse(_weight.text) ?? 70,
      heightCm: double.tryParse(_height.text) ?? 170,
      age: _age.round(),
      isMale: _gender == Gender.male,
    );
    final tdee =
        NutritionCalculator.tdee(bmrValue: bmr, activityFactor: _activity);
    return NutritionCalculator.calorieGoal(tdeeValue: tdee, goal: _goalType);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || !_hasUser) return;
    final user = _user!;
    user.gender = _gender;
    user.birthDate =
        DateTime(DateTime.now().year - _age.round(), 1, 1);
    user.heightCm = double.parse(_height.text.trim());
    user.targetWeightKg = double.parse(_weight.text.trim());
    user.activityFactor = _activity;
    user.isOnboarded = true;

    final calories = _recommended;
    user.calorieGoal = calories;

    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    await app.saveGoal(_goalType, calories);
    await auth.updateUserProfile(user);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
        '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding
            ? 'Définir votre objectif'
            : 'Mon objectif'),
      ),
      body: !_hasUser
          ? const Center(child: Text('Aucun utilisateur connecté.'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                children: [
                  Text('Sexe',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppDimensions.paddingSm),
                  SegmentedButton<Gender>(
                    segments: const [
                      ButtonSegment(
                          value: Gender.male,
                          label: Text('Homme'),
                          icon: Icon(Icons.male)),
                      ButtonSegment(
                          value: Gender.female,
                          label: Text('Femme'),
                          icon: Icon(Icons.female)),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (s) =>
                        setState(() => _gender = s.first),
                  ),
                  const SizedBox(height: AppDimensions.paddingLg),
                  AppTextField(
                    controller: _birthYear,
                    label: 'Année de naissance',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final y = int.tryParse(v?.trim() ?? '');
                      if (y == null ||
                          y < 1920 ||
                          y > DateTime.now().year - 10) {
                        return 'Année invalide';
                      }
                      return null;
                    },
                    onSubmitted: () => setState(() {}),
                  ),
                  AppTextField(
                    controller: _height,
                    label: 'Taille (cm)',
                    icon: Icons.straighten,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: Validators.positiveNumber,
                  ),
                  AppTextField(
                    controller: _weight,
                    label: 'Poids actuel (kg)',
                    icon: Icons.speed,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: Validators.weight,
                  ),
                  const SizedBox(height: AppDimensions.paddingSm),
                  Text('Niveau d\'activité',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppDimensions.paddingSm),
                  DropdownButtonFormField<double>(
                    value: _activity,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: NutritionCalculator.activityLevels
                        .map((l) => DropdownMenuItem(
                            value: l.factor, child: Text(l.label)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _activity = v ?? _activity),
                  ),
                  const SizedBox(height: AppDimensions.paddingLg),
                  Text('Objectif',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppDimensions.paddingSm),
                  ...GoalType.values.map((g) => RadioListTile<GoalType>(
                        value: g,
                        groupValue: _goalType,
                        title: Text(g.label),
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _goalType = v!),
                      )),
                  const SizedBox(height: AppDimensions.paddingMd),
                  AppCard(
                    color: AppColors.primarySoft,
                    child: Row(
                      children: [
                        const Icon(Icons.calculate_outlined,
                            color: AppColors.primaryDark),
                        const SizedBox(width: AppDimensions.paddingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Besoins estimés',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                              Text(
                                  '${_recommended.round()} kcal / jour',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          color:
                                              AppColors.primaryDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingLg),
                  AppButton(
                    label: 'Enregistrer',
                    icon: Icons.check,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}
