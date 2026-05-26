import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../utils/app_snackbar.dart';

class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Criar Encontro'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),

        child: ListView(
          children: [

            Text(
              'Novo Encontro',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 8),

            Text(
              'Organize um rolê automotivo na sua região.',
              style: AppTextStyles.subtitle,
            ),

            const SizedBox(height: 24),

           const CustomInput(
  hint: 'Nome do encontro',
  icon: Icons.drive_eta,
),

            const SizedBox(height: 16),

            const CustomInput(
              hint: 'Local',
              icon: Icons.location_on,
            ),

            const SizedBox(height: 16),

            const CustomInput(
              hint: 'Horário',
              icon: Icons.access_time,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              dropdownColor: AppColors.surface,

              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),

              items: const [

                DropdownMenuItem(
                  value: 'JDM',
                  child: Text('JDM'),
                ),

                DropdownMenuItem(
                  value: 'Street',
                  child: Text('Street'),
                ),

                DropdownMenuItem(
                  value: 'Premium',
                  child: Text('Premium'),
                ),

                DropdownMenuItem(
                  value: 'Drift',
                  child: Text('Drift'),
                ),
              ],

              onChanged: (value) {},
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: 'Publicar Encontro',
              icon: Icons.rocket_launch,
              onPressed: () {
                AppSnackbar.show(
                 context,
                  'Encontro publicado com sucesso!',
                 );
              },
            ),
          ],
        ),
      ),
    );
  }
}