import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../event_details/event_details_screen.dart';

class RealMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> events;

  const RealMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.events = const [],
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(latitude, longitude),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.nightpoint.app',
        ),

        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(latitude, longitude),
              width: 80,
              height: 80,
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
                size: 40,
              ),
            ),

            ...events
                .where(
                  (event) =>
                      event['latitude'] != null &&
                      event['longitude'] != null,
                )
                .map(
                  (event) {
                    final eventLatitude =
                        (event['latitude'] as num).toDouble();
                    final eventLongitude =
                        (event['longitude'] as num).toDouble();

                    return Marker(
                      point: LatLng(eventLatitude, eventLongitude),
                      width: 160,
                      height: 80,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(
                                eventId: event['id'],
                                title: event['title'] ?? 'Sem título',
                                location:
                                    event['location'] ?? 'Local não informado',
                                time: event['time'] ?? 'Horário não informado',
                                category: event['category'] ?? 'Evento',
                                description: event['description'] ?? '',
                                latitude: eventLatitude,
                                longitude: eventLongitude,
                                creatorName: event['creatorNickname'] ??
                                    event['creatorEmail'] ??
                                    'Criador não informado',
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary,
                                ),
                              ),
                              child: Text(
                                event['title'] ?? 'Evento',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              color: AppColors.accent,
                              size: 38,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ],
    );
  }
}