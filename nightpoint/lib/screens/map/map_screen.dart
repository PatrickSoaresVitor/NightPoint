import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/location_service.dart';
import '../../utils/app_snackbar.dart';
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

  bool isLoadingLocation = true;

  StreamSubscription<Position>? positionSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      setState(() {
        isLoadingLocation = true;
      });

      await positionSubscription?.cancel();

      positionSubscription = LocationService.getPositionStream().listen(
        (position) {
          if (!mounted) return;

          setState(() {
            latitude = position.latitude;
            longitude = position.longitude;
            isLoadingLocation = false;
          });
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            isLoadingLocation = false;
          });

          AppSnackbar.show(
            context,
            error.toString(),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
      });

      AppSnackbar.show(
        context,
        e.toString(),
      );
    }
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          final events = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return {
              'id': doc.id,
              ...data,
            };
          }).toList();

          return Stack(
            children: [
              Positioned.fill(
                child: latitude != null && longitude != null
                    ? RealMapWidget(
                        latitude: latitude!,
                        longitude: longitude!,
                        events: events,
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
              ),

              Positioned(
                top: 48,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_pin,
                        color: AppColors.primary,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mapa da Noite',
                              style: AppTextStyles.title.copyWith(
                                fontSize: 22,
                              ),
                            ),

                            Text(
                              '${events.length} encontro(s) encontrados',
                              style: AppTextStyles.subtitle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isLoadingLocation)
                Positioned(
                  bottom: 112,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Rastreamento de localização ativo...',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtitle,
                    ),
                  ),
                ),

              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateEventScreen(
                                  initialLatitude: latitude,
                                  initialLongitude: longitude,
                                ),
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
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      height: 56,
                      width: 56,
                      child: OutlinedButton(
                        onPressed:
                            isLoadingLocation ? null : _startLocationTracking,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor:
                              AppColors.background.withOpacity(0.85),
                        ),
                        child: isLoadingLocation
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}