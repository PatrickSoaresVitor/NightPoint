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
import '../../services/address_search_service.dart';

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
  final addressSearchService = AddressSearchService();

  String category = 'Street';

  bool isLoading = false;
  bool isGeneratingDescription = false;
  bool isGeneratingCompleteEvent = false;
  bool isSearchingAddress = false;

  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();

    latitude = widget.initialLatitude;
    longitude = widget.initialLongitude;
  }

  Future<void> searchAddressAndSelectLocation() async {
    if (locationController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        'Digite um endereço ou nome de local para buscar.',
      );
      return;
    }

    try {
      setState(() {
        isSearchingAddress = true;
      });

      double? userLatitude = latitude ?? widget.initialLatitude;
      double? userLongitude = longitude ?? widget.initialLongitude;

      if (userLatitude == null || userLongitude == null) {
        try {
          final position = await LocationService.getCurrentPosition();

          userLatitude = position.latitude;
          userLongitude = position.longitude;
        } catch (_) {}
      }

      final results = await addressSearchService.searchAddresses(
        query: locationController.text.trim(),
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      if (!mounted) return;

      final selectedResult = await showModalBottomSheet<AddressSearchResult>(
        context: context,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Escolha o endereço correto',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final result = results[index];

                        final distanceText = result.distanceKm == null
                            ? null
                            : result.distanceKm! < 1
                                ? '${(result.distanceKm! * 1000).round()} m'
                                : '${result.distanceKm!.toStringAsFixed(1)} km';

                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            result.displayName,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: distanceText == null
                              ? null
                              : Text(
                                  'Aprox. $distanceText de você',
                                  style: AppTextStyles.subtitle,
                                ),
                          onTap: () {
                            Navigator.pop(context, result);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (selectedResult == null) return;

      final selectedPosition = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            initialLatitude: selectedResult.position.latitude,
            initialLongitude: selectedResult.position.longitude,
          ),
        ),
      );

      if (!mounted) return;

      final finalPosition = selectedPosition ?? selectedResult.position;

      setState(() {
        latitude = finalPosition.latitude;
        longitude = finalPosition.longitude;
        locationController.text = selectedResult.displayName;
      });

      AppSnackbar.show(
        context,
        'Local do encontro definido pelo endereço!',
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSearchingAddress = false;
        });
      }
    }
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
        //timeController.text = generatedEvent['time'] ?? ''; desativado
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
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ),
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

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isSearchingAddress ? null : searchAddressAndSelectLocation,
              icon: Icon(
                isSearchingAddress ? Icons.hourglass_empty : Icons.search,
              ),
              label: Text(
                isSearchingAddress ? 'Buscando endereço...' : 'Buscar endereço no mapa',
              ),
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
                hasLocation ? Icons.edit_location_alt : Icons.map,
              ),
              label: Text(
                hasLocation
                    ? 'Ajustar local manualmente no mapa'
                    : 'Escolher local manualmente no mapa',
              ),
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

            if (hasLocation) ...[
              const SizedBox(height: 10),

              Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Local do encontro selecionado',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

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