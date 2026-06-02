import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const LocationPickerScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController mapController = MapController();

  static const double defaultZoom = 17.4;

  double currentZoom = defaultZoom;
  LatLng? selectedPoint;

  @override
  void initState() {
    super.initState();

    selectedPoint = LatLng(
      widget.initialLatitude,
      widget.initialLongitude,
    );
  }

  void confirmLocation() {
    if (selectedPoint == null) return;

    Navigator.pop(context, selectedPoint);
  }

  void centerOnInitialLocation() {
    final point = LatLng(
      widget.initialLatitude,
      widget.initialLongitude,
    );

    mapController.move(
      point,
      defaultZoom,
    );

    setState(() {
      currentZoom = defaultZoom;
      selectedPoint = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(
                widget.initialLatitude,
                widget.initialLongitude,
              ),
              initialZoom: defaultZoom,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedPoint = point;
                });
              },
              onMapEvent: (event) {
                final newZoom = event.camera.zoom;

                if (newZoom != currentZoom) {
                  setState(() {
                    currentZoom = newZoom;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.nightpoint.app',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      widget.initialLatitude,
                      widget.initialLongitude,
                    ),
                    width: 60,
                    height: 60,
                    child: Transform.rotate(
                      angle: 0.8,
                      child: const Icon(
                        Icons.navigation,
                        color: AppColors.primary,
                        size: 38,
                      ),
                    ),
                  ),

                  if (selectedPoint != null)
                    Marker(
                      point: selectedPoint!,
                      width: _getSelectedMarkerWidth(),
                      height: _getSelectedMarkerHeight(),
                      child: _buildSelectedMarker(),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.90),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: const Text(
                'Toque no mapa para escolher o local do encontro.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
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
                  child: CustomButton(
                    text: 'Confirmar Local',
                    icon: Icons.check_circle,
                    onPressed: confirmLocation,
                  ),
                ),

                const SizedBox(width: 12),

                SizedBox(
                  height: 56,
                  width: 56,
                  child: OutlinedButton(
                    onPressed: centerOnInitialLocation,
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
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getSelectedMarkerWidth() {
    if (currentZoom < 16.0) {
      return 22;
    }

    if (currentZoom < 19.0) {
      return 130;
    }

    return 190;
  }

  double _getSelectedMarkerHeight() {
    if (currentZoom < 16.0) {
      return 22;
    }

    if (currentZoom < 19.0) {
      return 34;
    }

    return 88;
  }

  Widget _buildSelectedMarker() {
    if (currentZoom < 16.0) {
      return Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.background,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.45),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    }

    if (currentZoom < 19.0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.primary,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 6),

            const Flexible(
              child: Text(
                'Local escolhido',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.20),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent,
                width: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Local escolhido',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Confirmar abaixo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}