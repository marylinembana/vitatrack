import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../data/models/nutritionist_model.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';

/// Écran de vérification du compte nutritionniste.
///
/// Affiché tant que le professionnel n'a pas été validé par un administrateur.
/// Il permet de compléter puis de soumettre son dossier (diplômes, agrément).
class NutritionistVerificationScreen extends StatefulWidget {
  const NutritionistVerificationScreen({super.key});

  @override
  State<NutritionistVerificationScreen> createState() =>
      _NutritionistVerificationScreenState();
}

class _NutritionistVerificationScreenState
    extends State<NutritionistVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nutritionist = auth.currentNutritionist;

    if (nutritionist == null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (_) => false),
            child: const Text('Retour à la connexion'),
          ),
        ),
      );
    }

    final rejected =
        nutritionist.verificationStatus == VerificationStatus.rejected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du compte'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          _StatusBanner(
            status: nutritionist.verificationStatus,
            rejected: rejected,
            note: nutritionist.verificationNote,
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          AppCard(
            child: Column(
              children: [
                ProfileAvatar(
                  name: nutritionist.fullName,
                  photoUrl: nutritionist.photoUrl,
                  radius: 34,
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                Text(nutritionist.fullName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(nutritionist.email,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppDimensions.paddingSm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                        icon: Icons.badge_outlined,
                        label: nutritionist.specialization),
                    _Chip(
                        icon: Icons.assignment_outlined,
                        label:
                            'N° ${nutritionist.licenseNumber.isEmpty ? '—' : nutritionist.licenseNumber}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Text('Documents du dossier',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.paddingSm),
          if (nutritionist.diplomaUrls.isEmpty)
            const AppCard(
                child: Text(
              'Aucun diplôme ou attestation fourni. Ajoutez-en pour pouvoir '
              'être vérifié.',
              style: TextStyle(color: AppColors.warning),
            ))
          else
            _DiplomaGrid(urls: nutritionist.diplomaUrls),
          const SizedBox(height: AppDimensions.paddingLg),
          AppButton(
            label: 'Compléter / modifier mon dossier',
            icon: Icons.edit_outlined,
            onPressed: () => _openEditSheet(context, nutritionist),
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          if (!nutritionist.isProfileComplete)
            _InfoNote(
              text:
                  'Votre dossier doit contenir au minimum une spécialisation, '
              "un n° d'agrément et au moins un diplôme.",
            ),
        ],
      ),
    );
  }

  Future<void> _openEditSheet(
      BuildContext context, NutritionistModel current) async {
    final nameC = TextEditingController(text: current.fullName);
    final specC = TextEditingController(text: current.specialization);
    final licenseC = TextEditingController(text: current.licenseNumber);
    final phoneC = TextEditingController(text: current.phone);
    final cityC = TextEditingController(text: current.city);
    final expC =
        TextEditingController(text: '${current.experienceYears}');
    final bioC = TextEditingController(text: current.bio);
    final diplomaC = TextEditingController();
    final diplomas = <String>[...current.diplomaUrls];
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.paddingMd,
            right: AppDimensions.paddingMd,
            top: AppDimensions.paddingMd,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                AppDimensions.paddingMd,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Mon dossier professionnel',
                      style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: AppDimensions.paddingMd),
                  AppTextField(
                      controller: nameC,
                      label: 'Nom complet',
                      validator: (v) =>
                          Validators.required(v, field: 'Le nom')),
                  AppTextField(
                      controller: specC,
                      label: 'Spécialisation',
                      validator: (v) => Validators.required(v,
                          field: 'La spécialisation')),
                  AppTextField(
                      controller: licenseC,
                      label: "N° d'agrément",
                      validator: (v) => Validators.required(v,
                          field: "Le n° d'agrément")),
                  Row(
                    children: [
                      Expanded(
                          child: AppTextField(
                              controller: phoneC,
                              label: 'Téléphone')),
                      const SizedBox(width: AppDimensions.paddingSm),
                      Expanded(
                          child: AppTextField(
                              controller: cityC, label: 'Ville')),
                    ],
                  ),
                  AppTextField(
                    controller: expC,
                    label: "Années d'expérience",
                    keyboardType: TextInputType.number,
                  ),
                  AppTextField(
                      controller: bioC,
                      label: 'Présentation',
                      maxLines: 3),
                  const SizedBox(height: AppDimensions.paddingSm),
                  Text('Diplômes & attestations',
                      style: Theme.of(sheetContext).textTheme.titleSmall),
                  AppTextField(
                    controller: diplomaC,
                    label: 'Lien du document',
                    suffix: IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      onPressed: () {
                        final url = diplomaC.text.trim();
                        if (url.isEmpty) return;
                        setSheet(() {
                          diplomas.add(url);
                          diplomaC.clear();
                        });
                      },
                    ),
                  ),
                  if (diplomas.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < diplomas.length; i++)
                          InputChip(
                            label: Text('Document ${i + 1}'),
                            onDeleted: () =>
                                setSheet(() => diplomas.removeAt(i)),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppDimensions.paddingMd),
                  ElevatedButton(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      final updated = NutritionistModel(
                        id: current.id,
                        email: current.email,
                        fullName: nameC.text.trim(),
                        photoUrl: current.photoUrl,
                        specialization: specC.text.trim(),
                        licenseNumber: licenseC.text.trim(),
                        bio: bioC.text.trim(),
                        phone: phoneC.text.trim(),
                        city: cityC.text.trim(),
                        experienceYears:
                            int.tryParse(expC.text.trim()) ?? 0,
                        diplomaUrls: diplomas,
                        patientIds: current.patientIds,
                        isVerified: current.isVerified,
                        verificationStatus:
                            VerificationStatus.pending,
                        createdAt: current.createdAt,
                      );
                      await context
                          .read<AuthProvider>()
                          .updateNutritionistProfile(updated);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: const Text('Soumettre à vérification'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final VerificationStatus status;
  final bool rejected;
  final String? note;
  const _StatusBanner({
    required this.status,
    required this.rejected,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final color = rejected ? AppColors.error : AppColors.warning;
    final icon = rejected ? Icons.error_outline : Icons.hourglass_top;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rejected
                      ? 'Dossier à corriger'
                      : 'Compte en cours de vérification',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  note ??
                      (rejected
                          ? 'Un administrateur a demandé des modifications. '
                              'Mettez à jour votre dossier puis re-soumettez-le.'
                          : 'Notre équipe vérifie vos diplômes et votre '
                              'agrément. Vous recevrez l\'accès dès validation.'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiplomaGrid extends StatelessWidget {
  final List<String> urls;
  const _DiplomaGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.paddingSm,
      runSpacing: AppDimensions.paddingSm,
      children: [
        for (final u in urls)
          FoodThumb(imageUrl: u, emoji: '📄', size: 84),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.paddingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

