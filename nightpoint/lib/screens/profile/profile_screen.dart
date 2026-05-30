import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import '../../services/auth_service.dart';

import '../../utils/app_snackbar.dart';

import '../../widgets/custom_card.dart';

import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Perfil'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),

        child: ListView(
          children: [

            CustomCard(
              child: Column(
                children: [

                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surface,
                    child: Text(
                      authService.currentUser?.email
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    authService.currentUser?.email ?? 'Usuário',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 26,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Conta autenticada no Firebase',
                    style: AppTextStyles.subtitle,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,

                    children: const [

                      ProfileStat(
                        label: 'Eventos',
                        value: '8',
                      ),

                      ProfileStat(
                        label: 'Conexões',
                        value: '24',
                      ),

                      ProfileStat(
                        label: 'Garagem',
                        value: '1',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            CustomCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    'Badges',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,

                    children: const [

                      BadgeChip(
                        text: 'Founder',
                      ),

                      BadgeChip(
                        text: 'Street Member',
                      ),

                      BadgeChip(
                        text: 'Night Crew',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,

              child: OutlinedButton.icon(

                onPressed: () async {

                  await authService.logout();

                  if (!context.mounted) return;

                  AppSnackbar.show(
                    context,
                    'Você saiu da conta.',
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(),
                    ),
                  );
                },

                icon: const Icon(Icons.logout),

                label: const Text(
                  'Sair da conta',
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,

                  side: const BorderSide(
                    color: AppColors.danger,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const ProfileStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        Text(
          value,

          style: AppTextStyles.title.copyWith(
            fontSize: 24,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }
}

class BadgeChip extends StatelessWidget {
  final String text;

  const BadgeChip({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {

    return Chip(

      label: Text(text),

      backgroundColor: AppColors.surface,

      labelStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),

      side: const BorderSide(
        color: AppColors.border,
      ),
    );
  }
}