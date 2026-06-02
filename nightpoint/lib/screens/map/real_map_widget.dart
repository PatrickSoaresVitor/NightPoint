import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../event_details/event_details_screen.dart';

class RealMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> events;
  final int recenterTrigger;

  const RealMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.events = const [],
    this.recenterTrigger = 0,
  });

  @override
  State<RealMapWidget> createState() => _RealMapWidgetState();
}

class _RealMapWidgetState extends State<RealMapWidget> {
  final MapController mapController = MapController();

  static const double defaultZoom = 17.4;

  double currentZoom = defaultZoom;

  @override
  void didUpdateWidget(covariant RealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.recenterTrigger != oldWidget.recenterTrigger) {
      mapController.move(
        LatLng(widget.latitude, widget.longitude),
        defaultZoom,
      );

      setState(() {
        currentZoom = defaultZoom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(
              widget.latitude,
              widget.longitude,
            ),
            initialZoom: currentZoom,
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
                // Marcador do usuário
                Marker(
                  point: LatLng(
                    widget.latitude,
                    widget.longitude,
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

                // Marcadores dos eventos
                ...widget.events
                    .where(
                      (event) =>
                          event['latitude'] != null &&
                          event['longitude'] != null,
                    )
                    .map((event) {
                  final eventLatitude = (event['latitude'] as num).toDouble();
                  final eventLongitude = (event['longitude'] as num).toDouble();

                  return Marker(
                    point: LatLng(
                      eventLatitude,
                      eventLongitude,
                    ),
                    width: _getMarkerWidth(),
                    height: _getMarkerHeight(),
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
                      child: _buildEventMarker(
                        event['title'] ?? 'Evento',
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Painel temporário para calibrar o zoom
        Positioned(
          top: 48,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary,
              ),
            ),
            child: Text(
              'Zoom: ${currentZoom.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getMarkerWidth() {
    // LONGE: antes do zoom 16 aparece só ponto
    if (currentZoom < 16.0) {
      return 22;
    }

    // MÉDIO: de 16 até antes de 19 aparece cápsula com nome
    if (currentZoom < 19.0) {
      return 120;
    }

    // DETALHADO: 19 ou mais
    return 190;
  }

  double _getMarkerHeight() {
    // LONGE
    if (currentZoom < 16.0) {
      return 22;
    }

    // MÉDIO
    if (currentZoom < 19.0) {
      return 34;
    }

    // DETALHADO
    return 88;
  }

  Widget _buildEventMarker(String title) {
    // LONGE = só ponto
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

    // MÉDIO = cápsula com nome
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

            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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

    // DETALHADO = card completo
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

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Toque para abrir',
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