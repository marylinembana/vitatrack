import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../data/models/nutritionist_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';

/// Profil professionnel du nutritionniste (consultation + édition complète).
class NutritionistProfileScreen extends StatelessWidget {
  const NutritionistProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nutritionist = auth.currentNutritionist;

    if (nutritionist == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Session introuvable.')),
      );
    }

    final plans =
        NutritionRepository.instance.byNutritionist(nutritionist.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil professionnel'),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEditSheet(context, nutritionist),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          _HeaderCard(nutritionist: nutritionist),
          const SizedBox(height: AppDimensions.paddingMd),
          _StatsRow(
            patients: nutritionist.patientIds.length,
            plans: plans.length,
            years: nutritionist.experienceYears,
          ),
          const SectionHeader(
              title: 'Cabinet & contact',
              padding: EdgeInsets.only(
                  top: AppDimensions.paddingLg,
                  bottom: AppDimensions.paddingSm)),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Spécialisation',
                    value: nutritionist.specialization),
                _InfoRow(
                    icon: Icons.assignment_outlined,
                    label: 'N° d\'agrément',
                    value: nutritionist.licenseNumber.isEmpty
                        ? 'Non renseigné'
                        : nutritionist.licenseNumber),
                _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: nutritionist.phone.isEmpty
                        ? 'Non renseigné'
                        : nutritionist.phone),
                _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: 'Ville',
                    value: nutritionist.city.isEmpty
                        ? 'Non renseignée'
                        : nutritionist.city,
                    isLast: true),
              ],
            ),
          ),
          if (nutritionist.bio.isNotEmpty) ...[
            const SectionHeader(
                title: 'Présentation',
                padding: EdgeInsets.only(
                    top: AppDimensions.paddingLg,
                    bottom: AppDimensions.paddingSm)),
            AppCard(
              child: Text(nutritionist.bio,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
          const SectionHeader(
              title: 'Diplômes & attestations',
              padding: EdgeInsets.only(
                  top: AppDimensions.paddingLg,
                  bottom: AppDimensions.paddingSm)),
          AppCard(
            child: nutritionist.diplomaUrls.isEmpty
                ? Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aucun document ajouté. Complétez votre dossier '
                          'pour faciliter votre vérification.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: AppDimensions.paddingSm,
                    runSpacing: AppDimensions.paddingSm,
                    children: [
                      for (final u in nutritionist.diplomaUrls)
                        FoodThumb(imageUrl: u, emoji: '📄', size: 84),
                    ],
                  ),
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          AppButton(
            label: 'Modifier mon profil',
            icon: Icons.edit_outlined,
            onPressed: () => _openEditSheet(context, nutritionist),
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          AppSecondaryButton(
            label: 'Se déconnecter',
            icon: Icons.logout,
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
    );
  }

  Future<void> _openEditSheet(
      BuildContext context, NutritionistModel current) async {
    final nameC = TextEditingController(text: current.fullName);
    final photoC = TextEditingController(text: current.photoUrl ?? '');
    final specC = TextEditingController(text: current.specialization);
    final licenseC = TextEditingController(text: current.licenseNumber);
    final phoneC = TextEditingController(text: current.phone);
    final cityC = TextEditingController(text: current.city);
    final expC = TextEditingController(text: '${current.experienceYears}');
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
                  Text('Modifier mon profil',
                      style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: AppDimensions.paddingMd),
                  Center(
                    child: ValueListenableBuilder(
                      valueListenable: nameC,
                      builder: (_, value, __) => ValueListenableBuilder(
                        valueListenable: photoC,
                        builder: (_, photoValue, ___) => PhotoPickerAvatar(
                          name: value.text.isEmpty ? '?' : value.text,
                          photoUrl: photoValue.text.trim().isEmpty
                              ? null
                              : photoValue.text.trim(),
                          radius: 34,
                          onChanged: (result) {
                            if (result == null) return;
                            setSheet(() => photoC.text = result);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMd),
                  photoHintLabel(context),
                  const SizedBox(height: AppDimensions.paddingSm),
                  AppTextField(
                      controller: nameC,
                      label: 'Nom complet',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          Validators.required(v, field: 'Le nom')),
                  AppTextField(
                      controller: specC,
                      label: 'Spécialisation',
                      icon: Icons.badge_outlined,
                      validator: (v) =>
                          Validators.required(v, field: 'La spécialisation')),
                  AppTextField(
                      controller: licenseC,
                      label: 'N° d\'agrément',
                      icon: Icons.assignment_outlined,
                      validator: (v) => Validators.required(v,
                          field: 'Le n° d\'agrément')),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                            controller: phoneC,
                            label: 'Téléphone',
                            icon: Icons.phone_outlined),
                      ),
                      const SizedBox(width: AppDimensions.paddingSm),
                      Expanded(
                        child: AppTextField(
                            controller: cityC,
                            label: 'Ville',
                            icon: Icons.location_city_outlined),
                      ),
                    ],
                  ),
                  AppTextField(
                    controller: expC,
                    label: 'Années d\'expérience',
                    icon: Icons.workspace_premium_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  AppTextField(
                      controller: bioC,
                      label: 'Présentation',
                      icon: Icons.notes_outlined,
                      maxLines: 3),
                  const SizedBox(height: AppDimensions.paddingSm),
                  Text('Diplômes & attestations',
                      style: Theme.of(sheetContext).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: diplomaC,
                    label: 'Lien du document (image URL)',
                    icon: Icons.image_outlined,
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
                            avatar: FoodThumb(
                                imageUrl: diplomas[i], emoji: '📄', size: 24),
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
                        photoUrl: photoC.text.trim().isEmpty
                            ? null
                            : photoC.text.trim(),
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
                        verificationStatus: current.verificationStatus,
                        verificationNote: current.verificationNote,
                        createdAt: current.createdAt,
                      );
                      await context
                          .read<AuthProvider>()
                          .updateNutritionistProfile(updated);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Profil mis à jour')));
                      }
                    },
                    child: const Text('Enregistrer'),
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

/// Bandeau d'en-tête : avatar, nom, statut de vérification, e-mail.
class _HeaderCard extends StatelessWidget {
  final NutritionistModel nutritionist;
  const _HeaderCard({required this.nutritionist});

  @override
  Widget build(BuildContext context) {
    final status = nutritionist.verificationStatus;
    final statusColor = switch (status) {
      VerificationStatus.verified => AppColors.success,
      VerificationStatus.pending => AppColors.warning,
      VerificationStatus.rejected => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            name: nutritionist.fullName,
            photoUrl: nutritionist.photoUrl,
            radius: 32,
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nutritionist.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(nutritionist.email,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == VerificationStatus.verified
                            ? Icons.verified
                            : status == VerificationStatus.pending
                                ? Icons.hourglass_top
                                : Icons.error_outline,
                        size: 13,
                        color: statusColor == AppColors.success
                            ? Colors.white
                            : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(status.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Trois chiffres clés du professionnel.
class _StatsRow extends StatelessWidget {
  final int patients;
  final int plans;
  final int years;

  const _StatsRow({
    required this.patients,
    required this.plans,
    required this.years,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _Stat(
                icon: Icons.groups_outlined,
                value: '$patients',
                caption: 'Patient(s)',
                color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
            child: _Stat(
                icon: Icons.restaurant_menu,
                value: '$plans',
                caption: 'Plan(s) créé(s)',
                color: AppColors.proteins)),
        const SizedBox(width: 10),
        Expanded(
            child: _Stat(
                icon: Icons.workspace_premium_outlined,
                value: years == 0 ? '—' : '$years ans',
                caption: 'Expérience',
                color: AppColors.accent)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String caption;
  final Color color;

  const _Stat({
    required this.icon,
    required this.value,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Text(caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.bodyMedium)),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

