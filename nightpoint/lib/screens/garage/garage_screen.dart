import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/garage_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import 'edit_garage_screen.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  Future<void> openModel3d(
    BuildContext context,
    String urlText,
  ) async {
    final cleanUrl = urlText.trim();

    if (cleanUrl.isEmpty) {
      AppSnackbar.show(
        context,
        'Nenhum modelo 3D cadastrado.',
      );
      return;
    }

    final url = Uri.tryParse(cleanUrl);

    if (url == null || !url.hasScheme) {
      AppSnackbar.show(
        context,
        'Link do modelo 3D inválido.',
      );
      return;
    }

    final canOpen = await canLaunchUrl(url);

    if (!canOpen) {
      AppSnackbar.show(
        context,
        'Não foi possível abrir o modelo 3D.',
      );
      return;
    }

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

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

            final model3dType = data['model3dType'] ?? 'realistic';
            final model3dUrl = data['model3dUrl'] ?? '';

            final model3dLabel = model3dType == 'cartoon'
                ? 'Cartoon - Poly Pizza'
                : 'Realista - Sketchfab';

            final hasModel3d = model3dUrl.toString().trim().isNotEmpty;

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

                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modelo 3D',
                        style: AppTextStyles.title.copyWith(fontSize: 22),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        model3dLabel,
                        style: AppTextStyles.subtitle,
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: hasModel3d
                              ? () {
                                  openModel3d(
                                    context,
                                    model3dUrl.toString(),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.view_in_ar),
                          label: Text(
                            hasModel3d
                                ? 'Ver carro em 3D'
                                : 'Nenhum modelo 3D cadastrado',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: hasModel3d
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            side: BorderSide(
                              color: hasModel3d
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
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