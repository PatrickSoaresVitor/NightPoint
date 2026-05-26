import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surface,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '@nightdriver',
                    style: AppTextStyles.title.copyWith(fontSize: 26),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Membro desde 2026',
                    style: AppTextStyles.subtitle,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      ProfileStat(label: 'Eventos', value: '8'),
                      ProfileStat(label: 'Conexões', value: '24'),
                      ProfileStat(label: 'Garagem', value: '1'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Badges',
                    style: AppTextStyles.title.copyWith(fontSize: 22),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      BadgeChip(text: 'Founder'),
                      BadgeChip(text: 'Street Member'),
                      BadgeChip(text: 'Night Crew'),
                    ],
                  ),
                ],
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
        Text(label, style: AppTextStyles.subtitle),
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