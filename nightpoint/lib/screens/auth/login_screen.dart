import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import '../../services/auth_service.dart';

import '../../utils/app_snackbar.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final authService = AuthService();

  bool isLogin = true;

  Future<void> submit() async {

    try {
      if (!isLogin &&
            passwordController.text.trim() !=
                confirmPasswordController.text.trim()) {

          AppSnackbar.show(
            context,
            'As senhas não coincidem.',
          );

        return;
      }

      if (isLogin) {

        await authService.login(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

      } else {

        await authService.register(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );

    } catch (e) {

      AppSnackbar.show(
        context,
        e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,

      body: Center(
        child: SingleChildScrollView(

          padding: const EdgeInsets.all(
            AppSpacing.lg,
          ),

          child: Column(

            children: [

              Text(
                'NightPoint',
                style: AppTextStyles.title,
              ),

              const SizedBox(height: 12),

              Text(
                isLogin
                    ? 'Entre na sua conta'
                    : 'Crie sua conta',
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 32),

              CustomInput(
                hint: 'E-mail',
                icon: Icons.email,
                controller: emailController,
              ),

              const SizedBox(height: 16),

              CustomInput(
                hint: 'Senha',
                icon: Icons.lock,
                controller: passwordController,
                obscureText: true,
              ),
              
            if (!isLogin) ...[

              const SizedBox(height: 16),

              CustomInput(
                hint: 'Confirmar senha',
                icon: Icons.lock_outline,
                controller: confirmPasswordController,
                obscureText: true,
              ),
            ],
              const SizedBox(height: 24),

              CustomButton(
                text: isLogin
                    ? 'Entrar'
                    : 'Cadastrar',

                icon: Icons.login,

                onPressed: submit,
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {

                  setState(() {
                    isLogin = !isLogin;
                  });
                },

                child: Text(
                  isLogin
                      ? 'Criar conta'
                      : 'Já tenho conta',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}