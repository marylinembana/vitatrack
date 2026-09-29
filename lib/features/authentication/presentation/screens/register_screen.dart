import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';
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

  /// Documents (diplômes) importés depuis la galerie, en mémoire jusqu'à
  /// l'inscription : téléversés vers Supabase une fois le compte créé.
  final _docs = <_DocItem>[];

  bool _obscure = true;
  bool _isNutritionist = false;
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [
      _name, _email, _password, _confirm, _specialization, _license,
      _phone, _city, _experience,
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
      );
      if (!mounted) return;
      if (ok) {
        // Le compte vient d'être créé : on téléverse les documents vers
        // Supabase (le uid n'existe qu'après inscription) puis on complète
        // le profil avec les URLs obtenues.
        await _uploadDocuments(auth);
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
      // Lie le nouveau compte au tableau de bord avant l'onboarding,
      // sinon GoalSetupScreen reste sans utilisateur (redirection bloquée).
      final user = auth.currentUser;
      if (user != null) {
        await context.read<AppProvider>().bindUser(user);
      }
      if (!mounted) return;
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

  /// Ajoute des documents en les important depuis la galerie de l'appareil.
  Future<void> _addDocsFromGallery() async {
    try {
      final picked = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked.isEmpty) return;
      final items = <_DocItem>[];
      for (final x in picked) {
        items.add(_DocItem(
          bytes: await x.readAsBytes(),
          name: x.name.isNotEmpty ? x.name : 'document.jpg',
          contentType: x.mimeType ?? 'image/jpeg',
        ));
      }
      if (!mounted) return;
      setState(() => _docs.addAll(items));
    } catch (_) {
      if (mounted) {
        _showError('Galerie indisponible sur cet appareil.');
      }
    }
  }

  /// Téléverse les documents en mémoire et complète le profil nutritionniste
  /// avec les URLs publiques obtenues (à appeler après création du compte).
  Future<void> _uploadDocuments(AuthProvider auth) async {
    if (_docs.isEmpty) return;
    _setUploading(true);
    final urls = <String>[];
    for (final d in _docs) {
      final url = await ImageUploadService.uploadBytes(
        d.bytes,
        fileName: d.name,
        contentType: d.contentType,
      );
      if (url != null) urls.add(url);
    }
    if (urls.isNotEmpty) {
      final n = auth.currentNutritionist;
      if (n != null) {
        n.diplomaUrls = urls;
        await auth.updateNutritionistProfile(n);
      }
    }
    _setUploading(false);
  }

  void _setUploading(bool value) {
    if (mounted) setState(() => _uploading = value);
  }

  /// Vignette d'un document importé, supprimable.
  Widget _docThumbnail(int index) {
    final doc = _docs[index];
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Image.memory(doc.bytes, fit: BoxFit.cover),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () => setState(() => _docs.removeAt(index)),
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pastille « Ajouter depuis la galerie ».
  Widget _addDocTile() {
    return InkWell(
      onTap: _uploading ? null : _addDocsFromGallery,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.divider),
          color: AppColors.surface,
        ),
        child: _uploading
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                  const SizedBox(height: 2),
                  Text('Galerie',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
      ),
    );
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
                  loading: auth.isLoading || _uploading,
                  onPressed: _uploading ? null : _submit,
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
        const SizedBox(height: AppDimensions.paddingSm),
        Text('Diplômes & attestations',
            style: Theme.of(context).textTheme.titleSmall),
        Text(
          'Importez les images de vos documents depuis votre galerie. '
          'Obligatoire pour la vérification.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppDimensions.paddingSm),
        Wrap(
          spacing: AppDimensions.paddingSm,
          runSpacing: AppDimensions.paddingSm,
          children: [
            for (var i = 0; i < _docs.length; i++) _docThumbnail(i),
            _addDocTile(),
          ],
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

/// Document importé depuis la galerie, conservé en mémoire jusqu'à l'envoi.
class _DocItem {
  final Uint8List bytes;
  final String name;
  final String contentType;

  const _DocItem({
    required this.bytes,
    required this.name,
    required this.contentType,
  });
}

