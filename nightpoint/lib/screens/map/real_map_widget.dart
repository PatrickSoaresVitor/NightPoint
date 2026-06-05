import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../services/route_service.dart';
import '../../utils/app_snackbar.dart';
import '../event_details/event_details_screen.dart';

class RealMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> events;
  final int recenterTrigger;
  final bool showUserMarker;

  const RealMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.events = const [],
    this.recenterTrigger = 0,
    this.showUserMarker = true,
  });

  @override
  State<RealMapWidget> createState() => _RealMapWidgetState();
}

class _RealMapWidgetState extends State<RealMapWidget> {
  final MapController mapController = MapController();
  final RouteService routeService = RouteService();

  static const double defaultZoom = 17.4;

  double currentZoom = defaultZoom;

  LatLng? currentUserPosition;
  Map<String, dynamic>? selectedEvent;

  List<LatLng> routePoints = [];

  double? routeDistanceKm;
  double? routeDurationMinutes;

  bool isLoadingRoute = false;
  bool isRouteActive = false;

  StreamSubscription<Position>? positionSubscription;

  DateTime? lastRouteUpdate;
  LatLng? lastRouteUserPosition;

  @override
  void initState() {
    super.initState();

    currentUserPosition = LatLng(
      widget.latitude,
      widget.longitude,
    );

    startUserPositionListener();
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.recenterTrigger != oldWidget.recenterTrigger) {
      mapController.move(
        currentUserPosition ??
            LatLng(widget.latitude, widget.longitude),
        defaultZoom,
      );

      setState(() {
        currentZoom = defaultZoom;
      });
    }
  }

  void startUserPositionListener() {
    if (!widget.showUserMarker) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      final newPosition = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        currentUserPosition = newPosition;
      });

      if (isRouteActive && selectedEvent != null) {
        await updateRouteIfNeeded(newPosition);
      }
    });
  }

  Future<void> updateRouteIfNeeded(LatLng newPosition) async {
    final event = selectedEvent;

    if (event == null) return;

    final eventLatitudeValue = event['latitude'];
    final eventLongitudeValue = event['longitude'];

    if (eventLatitudeValue == null || eventLongitudeValue == null) return;

    final now = DateTime.now();

    final shouldUpdateByTime = lastRouteUpdate == null ||
        now.difference(lastRouteUpdate!).inSeconds >= 15;

    bool shouldUpdateByDistance = true;

    if (lastRouteUserPosition != null) {
      final distanceMoved = Geolocator.distanceBetween(
        lastRouteUserPosition!.latitude,
        lastRouteUserPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      shouldUpdateByDistance = distanceMoved >= 30;
    }

    if (!shouldUpdateByTime && !shouldUpdateByDistance) return;

    await calculateRouteToEvent(
      event: event,
      moveCamera: false,
      showSuccessMessage: false,
    );
  }

  Future<void> calculateRouteToEvent({
    required Map<String, dynamic> event,
    bool moveCamera = true,
    bool showSuccessMessage = true,
  }) async {
    final userPosition = currentUserPosition;

    if (userPosition == null) {
      AppSnackbar.show(
        context,
        'Localização atual não encontrada.',
      );
      return;
    }

    final eventLatitudeValue = event['latitude'];
    final eventLongitudeValue = event['longitude'];

    if (eventLatitudeValue == null || eventLongitudeValue == null) {
      AppSnackbar.show(
        context,
        'Evento sem localização.',
      );
      return;
    }

    final eventLatitude = (eventLatitudeValue as num).toDouble();
    final eventLongitude = (eventLongitudeValue as num).toDouble();

    try {
      setState(() {
        isLoadingRoute = true;
        selectedEvent = event;
      });

      final result = await routeService.getDrivingRoute(
        startLatitude: userPosition.latitude,
        startLongitude: userPosition.longitude,
        endLatitude: eventLatitude,
        endLongitude: eventLongitude,
      );

      if (!mounted) return;

      setState(() {
        routePoints = result.points;
        routeDistanceKm = result.distanceKm;
        routeDurationMinutes = result.durationMinutes;
        isRouteActive = true;
        lastRouteUpdate = DateTime.now();
        lastRouteUserPosition = userPosition;
      });

      if (moveCamera && result.points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(result.points);

        mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(48),
          ),
        );
      }

      if (showSuccessMessage) {
        AppSnackbar.show(
          context,
          'Rota carregada!',
        );
      }
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        'Não foi possível calcular a rota.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRoute = false;
        });
      }
    }
  }

  void clearRoute() {
    setState(() {
      selectedEvent = null;
      routePoints = [];
      routeDistanceKm = null;
      routeDurationMinutes = null;
      isRouteActive = false;
      lastRouteUpdate = null;
      lastRouteUserPosition = null;
    });
  }

  void openEventDetails(Map<String, dynamic> event) {
    final latitudeValue = event['latitude'];
    final longitudeValue = event['longitude'];

    final eventLatitude = latitudeValue == null
        ? null
        : (latitudeValue as num).toDouble();

    final eventLongitude = longitudeValue == null
        ? null
        : (longitudeValue as num).toDouble();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          eventId: event['id'],
          title: event['title'] ?? 'Sem título',
          location: event['location'] ?? 'Local não informado',
          date: event['date'] ?? 'Data não informada',
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
  }

  String get routeTimeText {
    final minutes = routeDurationMinutes;

    if (minutes == null) return '-- min';

    if (minutes < 60) {
      return '${minutes.round()} min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = (minutes % 60).round();

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}min';
  }

  String get routeDistanceText {
    final distance = routeDistanceKm;

    if (distance == null) return '-- km';

    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final userPosition = currentUserPosition ??
        LatLng(
          widget.latitude,
          widget.longitude,
        );

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
              urlTemplate:
                  'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              userAgentPackageName: 'com.nightpoint.app',
            ),

            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5,
                    color: AppColors.primary,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (widget.showUserMarker)
                  Marker(
                    point: userPosition,
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

                ...widget.events
                    .where(
                      (event) =>
                          event['latitude'] != null &&
                          event['longitude'] != null,
                    )
                    .map((event) {
                  final eventLatitude =
                      (event['latitude'] as num).toDouble();
                  final eventLongitude =
                      (event['longitude'] as num).toDouble();

                  return Marker(
                    point: LatLng(
                      eventLatitude,
                      eventLongitude,
                    ),
                    width: _getMarkerWidth(),
                    height: _getMarkerHeight(),
                    child: GestureDetector(
                      onTap: () {
                        calculateRouteToEvent(event: event);
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

        if (selectedEvent != null)
          Positioned(
            top: 96,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.route,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rota até o encontro',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              selectedEvent!['title'] ?? 'Evento selecionado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: clearRoute,
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLoadingRoute
                              ? Icons.hourglass_empty
                              : Icons.near_me,
                          color: AppColors.primary,
                          size: 18,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            isLoadingRoute
                                ? 'Calculando rota...'
                                : '$routeDistanceText • $routeTimeText estimado',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        openEventDetails(selectedEvent!);
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Ver detalhes do encontro'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  double _getMarkerWidth() {
    if (currentZoom < 16.0) {
      return 22;
    }

    if (currentZoom < 19.0) {
      return 132;
    }

    return 190;
  }

  double _getMarkerHeight() {
    if (currentZoom < 16.0) {
      return 22;
    }

    if (currentZoom < 19.0) {
      return 36;
    }

    return 88;
  }

  Widget _buildEventMarker(String title) {
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
      return Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 76,
            maxWidth: 124,
            minHeight: 28,
            maxHeight: 34,
          ),
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
                color: AppColors.primary.withOpacity(0.16),
                blurRadius: 7,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
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
            'Toque para rota',
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