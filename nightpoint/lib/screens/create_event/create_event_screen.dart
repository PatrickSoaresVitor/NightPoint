import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/ai_service.dart';
import '../../services/event_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import 'package:latlong2/latlong.dart';

import '../location_picker/location_picker_screen.dart';

class CreateEventScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const CreateEventScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final timeController = TextEditingController();
  final descriptionController = TextEditingController();

  final eventService = EventService();
  final aiService = AiService();

  String category = 'Street';
  bool isLoading = false;
  bool isGeneratingDescription = false;

  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();

    latitude = widget.initialLatitude;
    longitude = widget.initialLongitude;
  }

  Future<void> getEventLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Localização do encontro capturada!',
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    }
  }

  Future<void> generateDescriptionWithAI() async {
    if (titleController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Preencha nome, local e horário antes de usar a IA.',
      );

      return;
    }

    try {
      setState(() {
        isGeneratingDescription = true;
      });

      final description = await aiService.generateEventDescription(
        title: titleController.text.trim(),
        location: locationController.text.trim(),
        time: timeController.text.trim(),
        category: category,
      );

      descriptionController.text = description;

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Descrição gerada com IA!',
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingDescription = false;
        });
      }
    }
  }

  Future<void> chooseLocationOnMap() async {
    final initialLat = latitude ?? widget.initialLatitude;
    final initialLng = longitude ?? widget.initialLongitude;

    if (initialLat == null || initialLng == null) {
      AppSnackbar.show(
        context,
        'Aguarde a localização inicial carregar no mapa.',
      );

      return;
    }

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: initialLat,
          initialLongitude: initialLng,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      latitude = result.latitude;
      longitude = result.longitude;
    });

    AppSnackbar.show(
      context,
      'Local do encontro selecionado no mapa!',
    );
  }

  Future<void> saveEvent() async {
    if (titleController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Preencha nome, local e horário.',
      );

      return;
    }

    if (latitude == null || longitude == null) {
      AppSnackbar.show(
        context,
        'Capture a localização antes de publicar.',
      );

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await eventService.createEvent(
        title: titleController.text.trim(),
        location: locationController.text.trim(),
        time: timeController.text.trim(),
        category: category,
        description: descriptionController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
      );

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Encontro publicado com sucesso!',
      );

      titleController.clear();
      locationController.clear();
      timeController.clear();
      descriptionController.clear();

      setState(() {
        category = 'Street';
        latitude = null;
        longitude = null;
      });

      Navigator.pop(context);
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    timeController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;

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

            CustomInput(
              hint: 'Nome do encontro',
              icon: Icons.drive_eta,
              controller: titleController,
            ),

            const SizedBox(height: 16),

            CustomInput(
              hint: 'Local',
              icon: Icons.location_on,
              controller: locationController,
            ),

            const SizedBox(height: 16),

            CustomInput(
              hint: 'Horário',
              icon: Icons.access_time,
              controller: timeController,
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed:
                  isGeneratingDescription ? null : generateDescriptionWithAI,
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                isGeneratingDescription
                    ? 'Gerando descrição...'
                    : 'Gerar descrição com IA',
              ),
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

            const SizedBox(height: 16),

            CustomInput(
              hint: 'Descrição do encontro',
              icon: Icons.description,
              controller: descriptionController,
              maxLines: 3,
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
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  category = value;
                });
              },
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: chooseLocationOnMap,
              icon: Icon(
                hasLocation ? Icons.check_circle : Icons.map,
              ),
              label: Text(
                hasLocation
                    ? 'Local do encontro selecionado'
                    : 'Escolher local no mapa',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    hasLocation ? AppColors.accent : AppColors.primary,
                side: BorderSide(
                  color: hasLocation ? AppColors.accent : AppColors.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: isLoading ? 'Publicando...' : 'Publicar Encontro',
              icon: Icons.rocket_launch,
              onPressed: isLoading ? () {} : saveEvent,
            ),
          ],
        ),
      ),
    );
  }
}