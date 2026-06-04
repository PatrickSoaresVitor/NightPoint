import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/garage_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import 'model_3d_picker_screen.dart';

class EditGarageScreen extends StatefulWidget {
  final Map<String, dynamic>? garageData;

  const EditGarageScreen({
    super.key,
    this.garageData,
  });

  @override
  State<EditGarageScreen> createState() => _EditGarageScreenState();
}

class _EditGarageScreenState extends State<EditGarageScreen> {
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final colorController = TextEditingController();
  final model3dUrlController = TextEditingController();

  final garageService = GarageService();

  String category = 'Street';
  String model3dType = 'realistic';

  @override
  void initState() {
    super.initState();

    final data = widget.garageData;

    if (data != null) {
      brandController.text = data['brand'] ?? '';
      modelController.text = data['model'] ?? '';
      yearController.text = data['year'] ?? '';
      colorController.text = data['color'] ?? '';
      category = data['category'] ?? 'Street';
      model3dType = data['model3dType'] ?? 'realistic';
      model3dUrlController.text = data['model3dUrl'] ?? '';
    }
  }

  Future<void> saveGarage() async {
    if (brandController.text.trim().isEmpty ||
        modelController.text.trim().isEmpty ||
        yearController.text.trim().isEmpty ||
        colorController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Preencha todos os campos obrigatórios.',
      );

      return;
    }

    await garageService.saveGarage(
      brand: brandController.text.trim(),
      model: modelController.text.trim(),
      year: yearController.text.trim(),
      color: colorController.text.trim(),
      category: category,
      model3dType: model3dType,
      model3dUrl: model3dUrlController.text.trim(),
    );

    if (!mounted) return;

    AppSnackbar.show(
      context,
      'Garagem salva!',
    );

    Navigator.pop(context);
  }

  void openModelPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Model3dPickerScreen(
          initialBrand: brandController.text.trim(),
          initialModel: modelController.text.trim(),
          initialYear: yearController.text.trim(),
          initialType: model3dType,
        ),
      ),
    );
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    colorController.dispose();
    model3dUrlController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Minha Garagem'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            CustomInput(
              hint: 'Marca',
              icon: Icons.factory,
              controller: brandController,
            ),

            const SizedBox(height: 16),

            CustomInput(
              hint: 'Modelo',
              icon: Icons.directions_car,
              controller: modelController,
            ),

            const SizedBox(height: 16),

            CustomInput(
              hint: 'Ano',
              icon: Icons.calendar_month,
              controller: yearController,
            ),

            const SizedBox(height: 16),

            CustomInput(
              hint: 'Cor',
              icon: Icons.color_lens,
              controller: colorController,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: category,
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
                  value: 'Street',
                  child: Text('Street'),
                ),
                DropdownMenuItem(
                  value: 'JDM',
                  child: Text('JDM'),
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
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  category = value;
                });
              },
            ),

            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: model3dType,
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
                  value: 'realistic',
                  child: Text('Modelo 3D Realista - Sketchfab'),
                ),
                DropdownMenuItem(
                  value: 'cartoon',
                  child: Text('Modelo 3D Cartoon - Poly Pizza'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  model3dType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            CustomInput(
              hint: 'Link do modelo 3D',
              icon: Icons.view_in_ar,
              controller: model3dUrlController,
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: openModelPicker,
                icon: const Icon(Icons.travel_explore),
                label: const Text('Escolher carro 3D'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: 'Salvar Garagem',
              icon: Icons.save,
              onPressed: saveGarage,
            ),
          ],
        ),
      ),
    );
  }
}