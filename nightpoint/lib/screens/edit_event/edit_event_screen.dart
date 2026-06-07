import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import 'package:latlong2/latlong.dart';

import '../../services/address_search_service.dart';
import '../../services/location_service.dart';
import '../location_picker/location_picker_screen.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EditEventScreen({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
 final titleController = TextEditingController();
  final locationController = TextEditingController();
  final timeController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();

  final addressSearchService = AddressSearchService();

  double? latitude;
  double? longitude;

  String category = 'Street';
  bool isLoading = false;
  bool isSearchingAddress = false;

  @override
  void initState() {
    super.initState();

    titleController.text = widget.eventData['title'] ?? '';
    locationController.text = widget.eventData['location'] ?? '';
    timeController.text = widget.eventData['time'] ?? '';
    descriptionController.text = widget.eventData['description'] ?? '';
    category = widget.eventData['category'] ?? 'Street';
    dateController.text = widget.eventData['date'] ?? '';
    latitude = (widget.eventData['latitude'] as num?)?.toDouble();
    longitude = (widget.eventData['longitude'] as num?)?.toDouble();
  }

  Future<void> chooseLocationOnMap() async {
    double? initialLat = latitude;
    double? initialLng = longitude;

    if (initialLat == null || initialLng == null) {
      try {
        final position = await LocationService.getCurrentPosition();

        initialLat = position.latitude;
        initialLng = position.longitude;
      } catch (e) {
        AppSnackbar.show(
          context,
          'Não foi possível obter localização inicial.',
        );
        return;
      }
    }

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: initialLat!,
          initialLongitude: initialLng!,
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
      'Local ajustado manualmente!',
    );
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

      double? userLatitude = latitude;
      double? userLongitude = longitude;

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
                  const Text(
                    'Escolha o endereço correto',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
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
        'Local do encontro atualizado!',
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

  Future<void> updateEvent() async {
    if (titleController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        dateController.text.trim().isEmpty ||
        timeController.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Preencha nome, local, data e horário.');
      return;
    }
    if (latitude == null || longitude == null) {
      AppSnackbar.show(
        context,
        'Busque e confirme o local no mapa antes de salvar.',
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({
        'title': titleController.text.trim(),
        'location': locationController.text.trim(),
        'time': timeController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
        'date': dateController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
      });

      if (!mounted) return;

      AppSnackbar.show(context, 'Encontro atualizado!');
      Navigator.pop(context);
    } catch (e) {
      AppSnackbar.show(context, e.toString());
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
    titleController.dispose();
    locationController.dispose();
    timeController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Encontro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
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
                isSearchingAddress ? 'Buscando endereço...' : 'Buscar e ajustar no mapa',
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

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: chooseLocationOnMap,
              icon: const Icon(Icons.edit_location_alt),
              label: const Text('Ajustar local manualmente no mapa'),
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
            CustomInput(
              hint: 'Descrição',
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
                DropdownMenuItem(value: 'Street', child: Text('Street')),
                DropdownMenuItem(value: 'JDM', child: Text('JDM')),
                DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                DropdownMenuItem(value: 'Drift', child: Text('Drift')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  category = value;
                });
              },
            ),

            const SizedBox(height: 24),
            CustomButton(
              text: isLoading ? 'Salvando...' : 'Salvar Alterações',
              icon: Icons.save,
              onPressed: isLoading ? () {} : updateEvent,
            ),
          ],
        ),
      ),
    );
  }
}