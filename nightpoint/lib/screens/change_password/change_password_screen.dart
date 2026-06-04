import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> changePassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      AppSnackbar.show(
        context,
        'Preencha a nova senha e a confirmação.',
      );
      return;
    }

    if (newPassword.length < 6) {
      AppSnackbar.show(
        context,
        'A senha deve ter pelo menos 6 caracteres.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppSnackbar.show(
        context,
        'As senhas não conferem.',
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      await user.updatePassword(newPassword);

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Senha atualizada com sucesso!',
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        AppSnackbar.show(
          context,
          'Por segurança, saia e entre novamente antes de alterar a senha.',
        );
      } else {
        AppSnackbar.show(
          context,
          'Erro ao alterar senha: ${e.message ?? e.code}',
        );
      }
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alterar Senha'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListView(
              children: [
                Text(
                  'Segurança da conta',
                  style: AppTextStyles.title,
                ),

                const SizedBox(height: 8),

                Text(
                  'Defina uma nova senha para sua conta NightPoint.',
                  style: AppTextStyles.subtitle,
                ),

                const SizedBox(height: 24),

                CustomInput(
                  hint: 'Nova senha',
                  icon: Icons.lock,
                  controller: newPasswordController,
                  obscureText: true,
                ),

                const SizedBox(height: 16),

                CustomInput(
                  hint: 'Confirmar nova senha',
                  icon: Icons.lock_outline,
                  controller: confirmPasswordController,
                  obscureText: true,
                ),

                const SizedBox(height: 24),

                CustomButton(
                  text: isLoading ? 'Alterando...' : 'Alterar Senha',
                  icon: Icons.security,
                  onPressed: isLoading ? () {} : changePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}