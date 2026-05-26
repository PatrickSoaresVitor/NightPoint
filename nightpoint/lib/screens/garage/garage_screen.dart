import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_card.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Garagem'),
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
                      Icons.directions_car,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'BMW 320i F30',
                    style: AppTextStyles.title.copyWith(fontSize: 26),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Projeto Street Premium',
                    style: AppTextStyles.subtitle,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      GarageStat(label: 'Level', value: '12'),
                      GarageStat(label: 'XP', value: '840'),
                      GarageStat(label: 'Tags', value: '5'),
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
                    'Tags do Projeto',
                    style: AppTextStyles.title.copyWith(fontSize: 22),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      ProjectTag(text: 'Street'),
                      ProjectTag(text: 'BMW'),
                      ProjectTag(text: 'Stage 2'),
                      ProjectTag(text: 'Night Run'),
                      ProjectTag(text: 'Premium'),
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

class GarageStat extends StatelessWidget {
  final String label;
  final String value;

  const GarageStat({
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

class ProjectTag extends StatelessWidget {
  final String text;

  const ProjectTag({
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