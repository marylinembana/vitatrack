import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/user_model.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';
import '../controllers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Écran de connexion (tous rôles).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'user@vitatrack.app');
  final _password = TextEditingController(text: 'demo1234');
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(_email.text, _password.text);
    if (!mounted) return;
    if (auth.isSignedIn) {
      await _routeByRole(auth);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Échec de la connexion')),
      );
    }
  }

  Future<void> _routeByRole(AuthProvider auth) async {
    if (auth.role == UserRole.user) {
      await context
          .read<AppProvider>()
          .bindUser(auth.currentUser ?? UserModel(id: '', email: '', fullName: ''));
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
        auth.landingRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimensions.paddingXl),
                  const Text('🥗',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 56)),
                  const SizedBox(height: AppDimensions.paddingSm),
                  Text(
                    'Bon retour !',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Connectez-vous pour continuer votre suivi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXl),
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
                    suffix: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const ForgotPasswordScreen()),
                      ),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSm),
                  AppButton(
                    label: 'Se connecter',
                    loading: auth.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppDimensions.paddingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pas encore de compte ?"),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text("S'inscrire"),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.paddingMd),
                  _DemoHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline,
                  size: AppDimensions.iconSm, color: AppColors.accent),
              SizedBox(width: 6),
              Text('Comptes de démonstration',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('User : user@vitatrack.app\n'
              'Nutri : nutritionniste@vitatrack.app\n'
              'Admin : admin@vitatrack.app\n'
              'Mot de passe : demo1234',
              style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
