import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';

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
                  (event) => Marker(
                    point: LatLng(
                      event['latitude'],
                      event['longitude'],
                    ),
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.accent,
                      size: 42,
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}