import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class Model3dPickerScreen extends StatefulWidget {
  final String initialBrand;
  final String initialModel;
  final String initialYear;
  final String initialType;

  const Model3dPickerScreen({
    super.key,
    required this.initialBrand,
    required this.initialModel,
    required this.initialYear,
    required this.initialType,
  });

  @override
  State<Model3dPickerScreen> createState() => _Model3dPickerScreenState();
}

class _Model3dPickerScreenState extends State<Model3dPickerScreen> {
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final generationController = TextEditingController();
  final extraController = TextEditingController();

  String model3dType = 'realistic';

  @override
  void initState() {
    super.initState();

    brandController.text = widget.initialBrand;
    modelController.text = widget.initialModel;
    generationController.text = widget.initialYear;
    model3dType = widget.initialType;
  }

  String get sourceName {
    return model3dType == 'realistic' ? 'Sketchfab' : 'Poly Pizza';
  }

  Future<void> openSearch(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      AppSnackbar.show(
        context,
        'Preencha pelo menos marca ou modelo.',
      );
      return;
    }

    final encodedQuery = Uri.encodeComponent(cleanQuery);

    final url = model3dType == 'realistic'
        ? Uri.parse(
            'https://sketchfab.com/search?type=models&q=$encodedQuery',
          )
        : Uri.parse(
            'https://poly.pizza/search/$encodedQuery',
          );

    final canOpen = await canLaunchUrl(url);

    if (!canOpen) {
      AppSnackbar.show(
        context,
        'Não foi possível abrir a busca.',
      );
      return;
    }

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  String buildBestQuery() {
    final brand = brandController.text.trim();
    final model = modelController.text.trim();
    final generation = generationController.text.trim();
    final extra = extraController.text.trim();

    final parts = <String>[];

    if (brand.isNotEmpty) parts.add(brand);
    if (generation.isNotEmpty) {
      parts.add(generation);
    } else if (model.isNotEmpty) {
      parts.add(model);
    }

    if (extra.isNotEmpty) parts.add(extra);

    if (model3dType == 'realistic') {
      parts.add('car');
    } else {
      parts.add('car');
    }

    return parts.join(' ');
  }

  String buildGenericQuery() {
    final brand = brandController.text.trim();
    final model = modelController.text.trim();

    final parts = <String>[];

    if (brand.isNotEmpty) parts.add(brand);
    if (model.isNotEmpty) parts.add(model);

    if (model3dType == 'realistic') {
      parts.add('car');
    } else {
      parts.add('car');
    }

    return parts.join(' ');
  }

  String buildBrandQuery() {
  final brand = brandController.text.trim();

  if (brand.isEmpty) {
    return 'car';
  }

  return '$brand car';
}

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    generationController.dispose();
    extraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escolher Modelo 3D'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            Text(
              'Buscar carro 3D',
              style: AppTextStyles.title.copyWith(fontSize: 28),
            ),

            const SizedBox(height: 8),

            Text(
              'Preencha os dados e abra uma busca pronta. Depois escolha um modelo, copie o link e cole na garagem.',
              style: AppTextStyles.subtitle,
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
                  child: Text('Realista - Sketchfab'),
                ),
                DropdownMenuItem(
                  value: 'cartoon',
                  child: Text('Cartoon - Poly Pizza'),
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
              hint: 'Geração / código opcional. Ex: F30, E46, MK4',
              icon: Icons.code,
              controller: generationController,
            ),

            const SizedBox(height: 16),

            CustomInput(
              hint: 'Termo extra opcional. Ex: sedan, coupe, race',
              icon: Icons.search,
              controller: extraController,
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: 'Buscar melhor opção no $sourceName',
              icon: Icons.travel_explore,
              onPressed: () {
                openSearch(buildBestQuery());
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  openSearch(buildGenericQuery());
                },
                icon: const Icon(Icons.manage_search),
                label: const Text('Buscar mais genérico'),
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

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  openSearch(buildBrandQuery());
                },
                icon: const Icon(Icons.directions_car_filled),
                label: const Text('Buscar só pela marca'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(
                    color: AppColors.secondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Dica: se a busca específica não encontrar nada, use a busca genérica. Exemplo: em vez de “BMW 320i 2016 preta”, tente “BMW F30 car” ou “BMW car”.',
              style: AppTextStyles.subtitle.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}