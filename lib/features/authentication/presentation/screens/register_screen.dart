import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/auth_provider.dart';

/// Inscription : choix du type de compte (Patient ou Nutritionniste).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Champs professionnels (nutritionniste).
  final _specialization = TextEditingController();
  final _license = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _experience = TextEditingController(text: '0');
  final _bio = TextEditingController();
  final _diplomaInput = TextEditingController();
  final _diplomas = <String>[];

  bool _obscure = true;
  bool _isNutritionist = false;

  @override
  void dispose() {
    for (final c in [
      _name, _email, _password, _confirm, _specialization, _license,
      _phone, _city, _experience, _bio, _diplomaInput,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    if (_isNutritionist) {
      final ok = await auth.registerNutritionist(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        specialization: _specialization.text,
        licenseNumber: _license.text,
        phone: _phone.text,
        city: _city.text,
        experienceYears: int.tryParse(_experience.text.trim()) ?? 0,
        bio: _bio.text,
        diplomaUrls: _diplomas,
      );
      if (!mounted) return;
      if (ok) {
        navigator.pushNamedAndRemoveUntil(
            '/nutritionist/verification', (route) => false);
      } else {
        _showError(auth.error);
      }
      return;
    }

    final ok = await auth.register(
      fullName: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (ok) {
      navigator.pushNamedAndRemoveUntil(
          '/onboarding-setup', (route) => false);
    } else {
      _showError(auth.error);
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message ?? 'Inscription impossible'),
          backgroundColor: AppColors.error),
    );
  }

  void _addDiploma() {
    final url = _diplomaInput.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _diplomas.add(url);
      _diplomaInput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Rejoignez VitaTrack',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppDimensions.paddingSm),
                Text(
                  _isNutritionist
                      ? 'Créez votre profil professionnel. Il sera vérifié par '
                          'notre équipe avant votre accès.'
                      : 'Créez votre profil pour commencer le suivi.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingLg),
                _RoleSelector(
                  value: _isNutritionist,
                  onChanged: (v) => setState(() => _isNutritionist = v),
                ),
                const SizedBox(height: AppDimensions.paddingLg),
                AppTextField(
                  controller: _name,
                  label: 'Nom complet',
                  icon: Icons.person_outline,
                  validator: (v) => Validators.required(v, field: 'Le nom'),
                ),
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                AppTextField(
                  controller: _password,
                  label: 'Mot de passe',
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  validator: Validators.password,
                ),
                AppTextField(
                  controller: _confirm,
                  label: 'Confirmer le mot de passe',
                  icon: Icons.lock_reset_outlined,
                  obscureText: _obscure,
                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),
                  suffix: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                if (_isNutritionist) ..._nutritionistFields,
                const SizedBox(height: AppDimensions.paddingMd),
                AppButton(
                  label: _isNutritionist
                      ? 'Créer et soumettre à vérification'
                      : "S'inscrire",
                  loading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('J\'ai déjà un compte'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> get _nutritionistFields => [
        const SizedBox(height: AppDimensions.paddingMd),
        Text('Informations professionnelles',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppDimensions.paddingSm),
        AppTextField(
          controller: _specialization,
          label: 'Spécialisation',
          icon: Icons.eco_outlined,
          hint: 'Nutrition du sportif, pédiatrique…',
          validator: (v) =>
              Validators.required(v, field: 'La spécialisation'),
        ),
        AppTextField(
          controller: _license,
          label: "N° d'agrément / d'ordre",
          icon: Icons.badge_outlined,
          validator: (v) => Validators.required(v, field: "Le n° d'agrément"),
        ),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _phone,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSm),
            Expanded(
              child: AppTextField(
                controller: _city,
                label: 'Ville',
                icon: Icons.location_city_outlined,
              ),
            ),
          ],
        ),
        AppTextField(
          controller: _experience,
          label: "Années d'expérience",
          icon: Icons.timeline_outlined,
          keyboardType: TextInputType.number,
        ),
        AppTextField(
          controller: _bio,
          label: 'Présentation',
          icon: Icons.notes_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: AppDimensions.paddingSm),
        Text('Diplômes & attestations',
            style: Theme.of(context).textTheme.titleSmall),
        Text(
          'Ajoutez les liens vers vos documents (images). Obligatoire pour '
          'la vérification.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingSm),
        AppTextField(
          controller: _diplomaInput,
          label: 'Lien du document',
          icon: Icons.description_outlined,
          suffix: IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _addDiploma,
          ),
        ),
        if (_diplomas.isNotEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.paddingSm),
            child: Wrap(
              children: [
                for (var i = 0; i < _diplomas.length; i++)
                  InputChip(
                    label: Text('Document ${i + 1}'),
                    avatar: const Icon(Icons.check_circle_outline, size: 16),
                    onDeleted: () => setState(() => _diplomas.removeAt(i)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppDimensions.paddingMd),
      ];
}

/// Sélecteur de type de compte (Patient / Nutritionniste).
class _RoleSelector extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RoleSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            title: 'Patient',
            subtitle: 'Je suis suivi(e)',
            icon: Icons.person_outline,
            selected: !value,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingSm),
        Expanded(
          child: _RoleCard(
            title: 'Nutritionniste',
            subtitle: 'Je suis professionnel(le)',
            icon: Icons.medical_services_outlined,
            selected: value,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFDDE5DD),
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingMd,
                horizontal: AppDimensions.paddingSm),
            child: Column(
              children: [
                Icon(icon,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary),
                const SizedBox(height: AppDimensions.paddingSm),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        )),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

