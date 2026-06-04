import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/garage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import 'edit_garage_screen.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final garageService = GarageService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Garagem'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: StreamBuilder(
          stream: garageService.getGarage(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();

            if (data == null) {
              return ListView(
                children: [
                  CustomCard(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 70,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum carro cadastrado',
                          style: AppTextStyles.title.copyWith(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cadastre seu projeto para aparecer na sua garagem.',
                          style: AppTextStyles.subtitle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Cadastrar Garagem',
                    icon: Icons.add,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditGarageScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            }

            return ListView(
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
                        '${data['brand']} ${data['model']}',
                        style: AppTextStyles.title.copyWith(fontSize: 26),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${data['year']} • ${data['color']}',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 20),
                      GarageInfo(
                        label: 'Categoria',
                        value: data['category'] ?? 'Não informado',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Editar Garagem',
                  icon: Icons.edit,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditGarageScreen(
                          garageData: data,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GarageInfo extends StatelessWidget {
  final String label;
  final String value;

  const GarageInfo({
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