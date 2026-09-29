import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/auth_provider.dart';

/// Écran de choix d'un NOUVEAU mot de passe, ouvert après que l'utilisateur a
/// cliqué le lien envoyé par e-mail (« Mot de passe oublié »). Le client
/// Supabase a déjà établi une session de récupération : aucun mot de passe
/// actuel n'est demandé ici.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.completePasswordReset(_password.text);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mot de passe mis à jour. Vous êtes connecté.')),
      );
      Navigator.of(context)
          .pushReplacementNamed(auth.isSignedIn ? auth.landingRoute : '/login');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _expiredCard() {
    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialisation')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.link_off, size: 64, color: AppColors.error),
              const SizedBox(height: AppDimensions.paddingMd),
              Text(
                'Ce lien de réinitialisation est invalide ou a expiré.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Text(
                'Re-demandez un lien : il n\'est valable que quelques minutes '
                'et ne peut être utilisé qu\'une seule fois.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.paddingLg),
              AppButton(
                label: 'Demander un nouveau lien',
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed('/forgot-password'),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Aucun lien valide ouvert (expiration, lien copié hors session) :
    // on propose d'en redemander un plutôt qu'un formulaire inutilisable.
    if (!auth.isSignedIn) return _expiredCard();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
                const SizedBox(height: AppDimensions.paddingMd),
                Text(
                  'Choisissez un nouveau mot de passe pour votre compte.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDimensions.paddingLg),
                AppTextField(
                  controller: _password,
                  label: 'Nouveau mot de passe',
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  validator: Validators.password,
                ),
                AppTextField(
                  controller: _confirm,
                  label: 'Confirmer le mot de passe',
                  icon: Icons.lock_person_outlined,
                  obscureText: _obscure,
                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),
                  suffix: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                AppButton(
                  label: 'Enregistrer le mot de passe',
                  loading: auth.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
