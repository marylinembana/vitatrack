import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../data/models/user_model.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import '../../dashboard/user_dashboard/controllers/app_provider.dart';

/// Édition complète du profil utilisateur :
/// photo, identité, morphologie, niveau d'activité, objectif.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final UserModel? _user = context.read<AppProvider>().user;

  late final _name = TextEditingController(text: _user?.fullName ?? '');
  late final _email = TextEditingController(text: _user?.email ?? '');
  late final _photoUrl =
      TextEditingController(text: _user?.photoUrl ?? '');
  late final _height = TextEditingController(
      text: _user?.heightCm.toStringAsFixed(0) ?? '');
  late final _target = TextEditingController(
      text: _user?.targetWeightKg.toStringAsFixed(0) ?? '');

  late Gender _gender = _user?.gender ?? Gender.male;
  late DateTime _birthDate = _user?.birthDate ?? DateTime(1995, 1, 1);
  late double _activity = _user?.activityFactor ?? 1.375;
  late GoalType _goalType = _user?.goalType ?? GoalType.maintain;

  @override
  void initState() {
    super.initState();
    _photoUrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _photoUrl.dispose();
    _height.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    final user = _user;
    user.fullName = _name.text.trim();
    user.photoUrl =
        _photoUrl.text.trim().isEmpty ? null : _photoUrl.text.trim();
    user.heightCm = double.parse(_height.text.trim());
    user.targetWeightKg = double.parse(_target.text.trim());
    user.gender = _gender;
    user.birthDate = _birthDate;
    user.activityFactor = _activity;
    user.goalType = _goalType;

    await context.read<AuthProvider>().updateUserProfile(user);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ageYears = DateTime.now().year - _birthDate.year;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhotoSection(),
              const SectionHeader(title: 'Identité'),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _name,
                      label: 'Nom complet',
                      icon: Icons.person_outline,
                      validator: (v) => Validators.required(v, field: 'Le nom'),
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    AppTextField(
                      controller: _email,
                      label: 'E-mail',
                      icon: Icons.mail_outline,
                      enabled: false,
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Morphologie'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceChipToggle(
                            label: 'Homme',
                            selected: _gender == Gender.male,
                            onTap: () =>
                                setState(() => _gender = Gender.male),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChoiceChipToggle(
                            label: 'Femme',
                            selected: _gender == Gender.female,
                            onTap: () =>
                                setState(() => _gender = Gender.female),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                      child: _FieldShell(
                        icon: Icons.cake_outlined,
                        label: 'Date de naissance',
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.textHint),
                        child: Text(
                          '${_birthDate.day.toString().padLeft(2, '0')}/'
                          '${_birthDate.month.toString().padLeft(2, '0')}/'
                          '${_birthDate.year}  •  $ageYears ans',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    AppTextField(
                      controller: _height,
                      label: 'Taille (cm)',
                      icon: Icons.straighten,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.positiveNumber,
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    AppTextField(
                      controller: _target,
                      label: 'Poids cible (kg)',
                      icon: Icons.speed,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.weight,
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Niveau d\'activité'),
              AppCard(
                child: Column(
                  children: [
                    for (final level
                        in NutritionCalculator.activityLevels)
                      RadioListTile<double>(
                        contentPadding: EdgeInsets.zero,
                        value: level.factor,
                        groupValue: _activity,
                        activeColor: AppColors.primary,
                        title: Text(level.label,
                            style: Theme.of(context).textTheme.bodyMedium),
                        onChanged: (v) =>
                            setState(() => _activity = v ?? _activity),
                      ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Objectif'),
              AppCard(
                child: Column(
                  children: GoalType.values.map((g) {
                    return RadioListTile<GoalType>(
                      contentPadding: EdgeInsets.zero,
                      value: g,
                      groupValue: _goalType,
                      activeColor: AppColors.primary,
                      title: Text(g.label,
                          style: Theme.of(context).textTheme.bodyMedium),
                      onChanged: (v) =>
                          setState(() => _goalType = v ?? _goalType),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLg),
              AppButton(
                label: 'Enregistrer',
                icon: Icons.check,
                onPressed: _save,
              ),
              const SizedBox(height: AppDimensions.paddingLg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section photo : avatar cliquable (caméra, galerie, lien, suppression).
class _PhotoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_EditProfileScreenState>()!;
    final name = state._name.text.trim().isEmpty
        ? '?'
        : state._name.text.trim();
    final photo = state._photoUrl.text.trim();
    return Column(
      children: [
        Center(
          child: PhotoPickerAvatar(
            photoUrl: photo.isEmpty ? null : photo,
            name: name,
            radius: 46,
            onChanged: (value) {
              if (value == null) return;
              state._photoUrl.text = value.isEmpty ? '' : value;
            },
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMd),
        photoHintLabel(context),
      ],
    );
  }
}

class _ChoiceChipToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChipToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Enveloppe visuelle imitant un champ en lecture seule cliquable.
class _FieldShell extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;

  const _FieldShell({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        )),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
