import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/location_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_card.dart';
import '../create_event/create_event_screen.dart';
import 'real_map_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double? latitude;
  double? longitude;

  Future<void> _getLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Localização capturada com sucesso!',
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
      appBar: AppBar(
        title: const Text('NightPoint'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            Text(
              'Mapa da Noite',
              style: AppTextStyles.title.copyWith(fontSize: 28),
            ),

            const SizedBox(height: 8),

            Text(
              'Encontre encontros, comboios e pontos automotivos próximos.',
              style: AppTextStyles.subtitle,
            ),

            const SizedBox(height: 16),

            CustomCard(
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: latitude != null && longitude != null
                      ? RealMapWidget(
                          latitude: latitude!,
                          longitude: longitude!,
                        )
                      : const Center(
                          child: Icon(
                            Icons.map,
                            size: 90,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (latitude != null && longitude != null)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sua localização',
                      style: AppTextStyles.title.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Latitude: $latitude',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Longitude: $longitude',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),

            if (latitude != null && longitude != null)
              const SizedBox(height: 16),

            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Encontro em destaque',
                    style: AppTextStyles.title.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Night Meet Franca',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posto GT • Hoje • 22:30',
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Criar Encontro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Usar Minha Localização'),
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
          ],
        ),
      ),
    );
  }
}

class MapPin extends StatelessWidget {
  final String label;

  const MapPin({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.background,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}