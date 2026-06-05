import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/ai_service.dart';
import '../../services/event_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
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
  final ideaController = TextEditingController();
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final timeController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();

  final eventService = EventService();
  final aiService = AiService();

  String category = 'Street';

  bool isLoading = false;
  bool isGeneratingDescription = false;
  bool isGeneratingCompleteEvent = false;

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

  Future<void> generateCompleteEventWithAI() async {
    if (ideaController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Digite uma ideia para a IA preencher o evento.',
      );

      return;
    }

    try {
      setState(() {
        isGeneratingCompleteEvent = true;
      });

      final generatedEvent = await aiService.generateCompleteEvent(
        idea: ideaController.text.trim(),
      );

      setState(() {
        titleController.text = generatedEvent['title'] ?? '';
        locationController.text = generatedEvent['location'] ?? '';
        timeController.text = generatedEvent['time'] ?? '';
        descriptionController.text = generatedEvent['description'] ?? '';

        final generatedCategory = generatedEvent['category'] ?? 'Street';

        if (['Street', 'JDM', 'Premium', 'Drift']
            .contains(generatedCategory)) {
          category = generatedCategory;
        } else {
          category = 'Street';
        }
      });

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Evento preenchido com IA!',
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingCompleteEvent = false;
        });
      }
    }
  }

  Future<void> generateDescriptionWithAI() async {
    if (titleController.text.trim().isEmpty ||
      locationController.text.trim().isEmpty ||
      dateController.text.trim().isEmpty ||
      timeController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Preencha nome, local, data e horário antes de usar a IA.',
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
        date: dateController.text.trim(),
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

  Future<bool> confirmSafetyAnalysis(String analysis) async {
    final lowerAnalysis = analysis.toLowerCase();

    final isWarning = lowerAnalysis.contains('atenção') ||
        lowerAnalysis.contains('inadequado');

    if (!isWarning) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Atenção na publicação'),
          content: Text(
            analysis,
            style: AppTextStyles.subtitle,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Voltar e editar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Continuar mesmo assim',
                style: TextStyle(
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> saveEvent() async {
    if (titleController.text.trim().isEmpty ||
      locationController.text.trim().isEmpty ||
      dateController.text.trim().isEmpty ||
      timeController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Preencha nome, local, data e horário.',
      );

      return;
    }

    if (latitude == null || longitude == null) {
      AppSnackbar.show(
        context,
        'Escolha o local do encontro antes de publicar.',
      );

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final safetyAnalysis = await aiService.analyzeEventSafety(
        title: titleController.text.trim(),
        location: locationController.text.trim(),
        date: dateController.text.trim(),
        time: timeController.text.trim(),
        category: category,
        description: descriptionController.text.trim(),
      );

      if (!mounted) return;

      final canContinue = await confirmSafetyAnalysis(safetyAnalysis);

      if (!canContinue) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        return;
      }

      await eventService.createEvent(
        title: titleController.text.trim(),
        location: locationController.text.trim(),
        time: timeController.text.trim(),
        category: category,
        description: descriptionController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        date: dateController.text.trim(),
      );

      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Encontro publicado com sucesso!',
      );

      ideaController.clear();
      titleController.clear();
      locationController.clear();
      timeController.clear();
      descriptionController.clear();
      dateController.clear();

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
  Future<void> pickEventTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final hour = selectedTime.hour.toString().padLeft(2, '0');
    final minute = selectedTime.minute.toString().padLeft(2, '0');

    setState(() {
      timeController.text = '$hour:$minute';
    });
  }
  Future<void> pickEventDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();

    setState(() {
      dateController.text = '$day/$month/$year';
    });
  }

  @override
  void dispose() {
    ideaController.dispose();
    titleController.dispose();
    locationController.dispose();
    dateController.dispose();
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
              hint: 'Ideia do evento',
              icon: Icons.lightbulb,
              controller: ideaController,
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: isGeneratingCompleteEvent
                  ? null
                  : generateCompleteEventWithAI,
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                isGeneratingCompleteEvent
                    ? 'Preenchendo evento...'
                    : 'Preencher evento com IA',
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

            GestureDetector(
              onTap: pickEventDate,
              child: AbsorbPointer(
                child: CustomInput(
                  hint: 'Data',
                  icon: Icons.calendar_month,
                  controller: dateController,
                ),
              ),
            ),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: pickEventTime,
              child: AbsorbPointer(
                child: CustomInput(
                  hint: 'Horário',
                  icon: Icons.access_time,
                  controller: timeController,
                ),
              ),
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
              text: isLoading
                  ? 'Analisando e publicando...'
                  : 'Publicar Encontro',
              icon: Icons.rocket_launch,
              onPressed: isLoading ? () {} : saveEvent,
            ),
          ],
        ),
      ),
    );
  }
  
}